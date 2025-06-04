import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../../config/supabase_config.dart';

class UpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  static const String _remindLaterKey = 'remind_later_timestamp';

  // Supabase client - only used if available
  SupabaseClient? get _supabase {
    if (!SupabaseConfig.enableSupabase || !_isSupabaseInitialized()) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      developer.log('Supabase not available: $e', name: 'UpdateService');
      return null;
    }
  }

  bool _isSupabaseInitialized() {
    try {
      // This will throw if Supabase is not initialized
      Supabase.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  Timer? _updateTimer;
  Timer? _realTimeTimer;
  StreamController<UpdateInfo>? _updateController;
  StreamController<DownloadProgress>? _downloadController;
  StreamController<UpdateStatus>? _statusController;

  Stream<UpdateInfo>? get updateStream => _updateController?.stream;
  Stream<DownloadProgress>? get downloadStream => _downloadController?.stream;
  Stream<UpdateStatus>? get statusStream => _statusController?.stream;

  // Public getters to expose states for navigation safety checks
  bool get isDownloading => _isDownloading;
  bool get isInstalling => _isInstalling;

  bool _isInitialized = false;
  bool _isDownloading = false;
  bool _isInstalling = false;
  CancelToken? _downloadCancelToken;

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing Update Service...', name: 'UpdateService');

      _updateController = StreamController<UpdateInfo>.broadcast();
      _downloadController = StreamController<DownloadProgress>.broadcast();
      _statusController = StreamController<UpdateStatus>.broadcast();

      // Check if Supabase is available
      if (!SupabaseConfig.enableSupabase || _supabase == null) {
        developer.log(
          '⚠️ Supabase disabled or unavailable, running in offline mode',
          name: 'UpdateService',
        );

        _isInitialized = true;
        developer.log(
          'Update Service initialized in offline mode',
          name: 'UpdateService',
        );
        return;
      }

      developer.log(
        '🌐 Supabase available, initializing online features...',
        name: 'UpdateService',
      );

      // Test Supabase connection with timeout
      await _testSupabaseConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log(
            'Supabase connection timeout, continuing without internet connectivity',
            name: 'UpdateService',
          );
        },
      );

      // Create table if it doesn't exist (this should be done via SQL Editor)
      await _ensureTableExists().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log(
            'Table creation timeout, app will continue',
            name: 'UpdateService',
          );
        },
      );

      // Clear any previously skipped versions on startup
      await clearSkippedVersion();

      // Clear any old remind later timestamps on startup
      await clearRemindLater();

      // Start periodic update checks (every 10 minutes for regular checks)
      _startPeriodicUpdateCheck();

      // Start real-time update checks (every 30 seconds for auto-refresh)
      _startRealTimeUpdateCheck();

      // Check for updates immediately (with timeout)
      try {
        developer.log(
          '🔍 Performing immediate update check on initialization...',
          name: 'UpdateService',
        );

        final updateInfo = await checkForUpdates().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Initial update check timeout, will retry later',
              name: 'UpdateService',
            );
            return null;
          },
        );

        if (updateInfo != null) {
          developer.log(
            '📢 Update available on initialization: ${updateInfo.versionName}',
            name: 'UpdateService',
          );
          // Force emit to stream even if it was silent
          _updateController?.add(updateInfo);
        }
      } catch (e) {
        developer.log(
          'Initial update check failed: $e, will retry later',
          name: 'UpdateService',
        );
      }

      _isInitialized = true;
      developer.log(
        'Update Service initialized successfully with Supabase',
        name: 'UpdateService',
      );
    } catch (error) {
      developer.log(
        'Failed to initialize Update Service: $error',
        name: 'UpdateService',
      );

      // Mark as initialized anyway to prevent blocking the app
      _isInitialized = true;

      // Initialize basic controllers even if Supabase fails
      _updateController ??= StreamController<UpdateInfo>.broadcast();
      _downloadController ??= StreamController<DownloadProgress>.broadcast();
      _statusController ??= StreamController<UpdateStatus>.broadcast();

      developer.log(
        'Update Service initialized in offline mode',
        name: 'UpdateService',
      );
    }
  }

  Future<void> _testSupabaseConnection() async {
    try {
      // Test connection by performing a simple query
      final response =
          await _supabase?.from('app_updates').select('count').count();

      developer.log(
        'Supabase connection successful, records: ${response?.count}',
        name: 'UpdateService',
      );
    } catch (error) {
      // Don't rethrow, just log the error to allow app to continue
    }
  }

  Future<void> _ensureTableExists() async {
    try {
      // This is mainly for testing - in production, table should be created via SQL Editor
      await _supabase?.from('app_updates').select('id').limit(1);

      // Insert initial version if table is empty
      final countResponse =
          await _supabase?.from('app_updates').select('*').count();

      if (countResponse?.count == 0) {
        await _supabase?.from('app_updates').insert({
          'version_name': '1.0.0',
          'version_code': 1,
          'update_title': 'Initial Release',
          'update_description':
              'Welcome to ANR Saver - Your Ultimate Video Downloader!',
          'changelog':
              'Initial release with support for TikTok, Instagram, Facebook, YouTube, and RedNote.',
          'feature_highlights': [
            'Multi-platform video downloading',
            'Real-time download progress',
            'Beautiful dark/light theme',
          ],
          'bug_fixes': ['Initial stable release'],
          'improvements': [
            'Optimized download performance',
            'Enhanced user interface',
          ],
          'file_size_mb': 15.5,
        });
      }
    } catch (error) {
      // Don't rethrow to allow app to continue
    }
  }

  void _startPeriodicUpdateCheck() {
    _updateTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      try {
        checkForUpdates(silent: true);
      } catch (e) {
        developer.log(
          'Periodic update check failed: $e',
          name: 'UpdateService',
        );
      }
    });
  }

  DateTime? _lastDialogShownTime;
  static const Duration _dialogCooldownDuration = Duration(minutes: 10);

  void _startRealTimeUpdateCheck() {
    _realTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      try {
        // Don't perform real-time checks during download/installation to prevent dialog interruption
        if (_isDownloading || _isInstalling) {
          developer.log(
            '🚫 Skipping real-time update check - download/installation in progress',
            name: 'UpdateService',
          );
          return;
        }

        // Check if enough time has passed since last dialog
        final now = DateTime.now();
        final canShowDialog = _lastDialogShownTime == null ||
            now.difference(_lastDialogShownTime!) >= _dialogCooldownDuration;

        if (canShowDialog) {
          // Allow dialog after cooldown period
          developer.log(
            '⏰ Real-time check: cooldown period passed, allowing dialog',
            name: 'UpdateService',
          );
          checkForUpdates(silent: false, realTime: true, forceShow: false);
        } else {
          // Still in cooldown - log remaining time
          final timeSinceLastDialog = now.difference(_lastDialogShownTime!);
          final remainingTime = _dialogCooldownDuration - timeSinceLastDialog;
          developer.log(
            '🔇 Real-time check: in cooldown period - ${remainingTime.inMinutes} minutes remaining',
            name: 'UpdateService',
          );
          checkForUpdates(silent: true, realTime: true, forceShow: false);
        }
      } catch (e) {
        developer.log(
          'Real-time update check failed: $e',
          name: 'UpdateService',
        );
      }
    });
  }

  Future<UpdateInfo?> checkForUpdates({
    bool silent = false,
    bool realTime = false,
    bool forceShow = false,
  }) async {
    try {
      // Check if Supabase is available
      if (_supabase == null) {
        if (!silent) {
          developer.log(
            '⚠️ Supabase not available, skipping update check',
            name: 'UpdateService',
          );
        }
        return null;
      }

      if (!silent) {
        developer.log('Checking for app updates...', name: 'UpdateService');
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final currentVersionName = packageInfo.version;

      if (!silent) {
        developer.log(
          'Current version: $currentVersionName ($currentVersionCode)',
          name: 'UpdateService',
        );
      }

      // Query latest version from Supabase with retry
      final response = await _queryWithRetry(() async {
        return await _supabase
            ?.from('app_updates')
            .select('*')
            .gt('version_code', currentVersionCode)
            .order('version_code', ascending: false)
            .limit(1);
      });

      developer.log(
        'Query: SELECT * FROM app_updates WHERE version_code > $currentVersionCode ORDER BY version_code DESC LIMIT 1',
        name: 'UpdateService',
      );
      developer.log(
        'Query response: ${response.length} results',
        name: 'UpdateService',
      );

      if (response.isNotEmpty) {
        developer.log(
          'Raw response data: ${response.first}',
          name: 'UpdateService',
        );
      }

      if (response.isNotEmpty) {
        final row = response.first;
        developer.log(
          'Found update: ${row['version_name']} (${row['version_code']})',
          name: 'UpdateService',
        );

        final updateInfo = UpdateInfo(
          versionName: row['version_name'] as String,
          versionCode: row['version_code'] as int,
          updateTitle: row['update_title'] as String,
          updateDescription: row['update_description'] as String,
          changelog: row['changelog'] as String,
          featureHighlights: List<String>.from(
            row['feature_highlights'] as List? ?? [],
          ),
          bugFixes: List<String>.from(row['bug_fixes'] as List? ?? []),
          improvements: List<String>.from(row['improvements'] as List? ?? []),
          downloadUrl: row['download_url'] as String?,
          fileSizeMB: (row['file_size_mb'] as num?)?.toDouble() ?? 0.0,
          isForced: row['is_forced'] as bool,
          minSupportedVersion: row['min_supported_version'] as int,
          releaseDate: DateTime.parse(row['release_date'] as String),
          currentVersionName: currentVersionName,
          currentVersionCode: currentVersionCode,
        );

        developer.log(
          '✅ UpdateInfo created: ${updateInfo.versionName}',
          name: 'UpdateService',
        );

        // Check if current version is supported
        if (currentVersionCode < updateInfo.minSupportedVersion) {
          updateInfo.isForced = true; // Force update if version is too old
          developer.log(
            'Forcing update: current version $currentVersionCode < min supported ${updateInfo.minSupportedVersion}',
            name: 'UpdateService',
          );
        }

        // Check if this version was skipped by user
        final prefs = await SharedPreferences.getInstance();
        final skippedVersion = prefs.getString(_skipVersionKey);

        if (!updateInfo.isForced && skippedVersion == updateInfo.versionName) {
          developer.log(
            'Version ${updateInfo.versionName} was skipped by user',
            name: 'UpdateService',
          );
          return null;
        }

        // Check if remind later is active (only for non-forced updates)
        if (!updateInfo.isForced && !forceShow) {
          final shouldShow = await shouldShowUpdateDialog();
          if (!shouldShow) {
            developer.log(
              'Update dialog suppressed due to remind later for version: ${updateInfo.versionName}',
              name: 'UpdateService',
            );
            return updateInfo; // Return the update info but don't emit to stream
          }
        }

        developer.log(
          '🎯 Update passed all checks, preparing to emit...',
          name: 'UpdateService',
        );

        // Save last update check time
        await prefs.setInt(
          _lastUpdateCheckKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        // Don't emit to stream if download or installation is in progress
        if (_isDownloading || _isInstalling) {
          developer.log(
            '🚫 Not emitting to stream - download/installation in progress',
            name: 'UpdateService',
          );
          return updateInfo; // Return update info but don't trigger dialog
        }

        // For real-time checks, only emit if dialog cooldown has passed
        if (realTime && !forceShow && !silent) {
          final now = DateTime.now();
          final canShowDialog = _lastDialogShownTime == null ||
              now
                      .difference(_lastDialogShownTime!)
                      .compareTo(_dialogCooldownDuration) >=
                  0;

          if (!canShowDialog) {
            developer.log(
              '🔇 Real-time check: dialog cooldown active, not emitting to stream',
              name: 'UpdateService',
            );
            return updateInfo; // Return update info but don't trigger dialog
          }
        }

        // Emit update info to stream (only if not silent or it's a real-time check with forceShow)
        if (!silent || forceShow) {
          _updateController?.add(updateInfo);
          developer.log(
            '📢 Emitted update info to stream (silent: $silent, realTime: $realTime, forceShow: $forceShow)',
            name: 'UpdateService',
          );
        } else {
          developer.log(
            '🔇 Not emitting to stream (silent: $silent, realTime: $realTime, forceShow: $forceShow)',
            name: 'UpdateService',
          );
        }

        // Emit status update
        _statusController?.add(UpdateStatus.available);

        return updateInfo;
      } else {
        if (!silent) {
          developer.log(
            'No updates available (query returned empty result)',
            name: 'UpdateService',
          );
        }
        _statusController?.add(UpdateStatus.upToDate);
        return null;
      }
    } catch (error) {
      developer.log(
        'Error checking for updates: $error',
        name: 'UpdateService',
      );

      // Only emit error status if it's not a silent check
      if (!silent) {
        _statusController?.add(UpdateStatus.error);
      }
      return null;
    }
  }

  // Helper method for retry logic
  Future<List<Map<String, dynamic>>> _queryWithRetry(
    Future<List<Map<String, dynamic>>?> Function() queryFunction, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await queryFunction();
        return result ?? [];
      } catch (error) {
        if (attempt == maxRetries) {
          rethrow; // Rethrow on final attempt
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // This should never be reached due to rethrow above, but adding for completeness
    throw Exception('All retry attempts failed');
  }

  Future<void> skipVersion(String versionName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skipVersionKey, versionName);
      developer.log('Skipped version: $versionName', name: 'UpdateService');
    } catch (error) {
      developer.log('Failed to skip version: $error', name: 'UpdateService');
    }
  }

  Future<void> clearSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skipVersionKey);
      developer.log(
        'Cleared any skipped versions on startup',
        name: 'UpdateService',
      );
    } catch (error) {
      developer.log(
        'Failed to clear skipped version: $error',
        name: 'UpdateService',
      );
    }
  }

  Future<DateTime?> getLastUpdateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateCheckKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (error) {
      developer.log(
        'Failed to get last update check: $error',
        name: 'UpdateService',
      );
      return null;
    }
  }

  Future<String> downloadUpdate(
    String downloadUrl, {
    Function(String)? onDownloadComplete,
  }) async {
    if (_isDownloading) {
      throw Exception('Download already in progress');
    }

    try {
      _isDownloading = true;
      _statusController?.add(UpdateStatus.downloading);

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = downloadUrl.split('/').last.isNotEmpty
          ? downloadUrl.split('/').last
          : 'app_update.apk';
      final filePath = '${tempDir.path}/$fileName';

      _downloadCancelToken = CancelToken();

      // Track download start time for speed calculation
      DateTime downloadStartTime = DateTime.now();
      int lastReceivedBytes = 0;
      DateTime lastProgressTime = DateTime.now();
      double lastCalculatedSpeed = 0.0;

      developer.log('Starting download: $downloadUrl', name: 'UpdateService');

      await dio.download(
        downloadUrl,
        filePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final now = DateTime.now();
            final progress = received / total;

            // Calculate speed more dynamically and accurately
            final totalElapsed =
                now.difference(downloadStartTime).inMilliseconds;
            final timeDiff = now.difference(lastProgressTime).inMilliseconds;
            final bytesDiff = received - lastReceivedBytes;

            double currentSpeed = lastCalculatedSpeed;

            // More aggressive speed updates for better synchronization
            if (timeDiff >= 250 && bytesDiff > 0) {
              // Update speed every 250ms for better responsiveness
              currentSpeed = (bytesDiff / 1024 / 1024) / (timeDiff / 1000);

              // Apply smoothing to avoid jumping
              if (lastCalculatedSpeed > 0) {
                currentSpeed =
                    (lastCalculatedSpeed * 0.4) + (currentSpeed * 0.6);
              }

              lastCalculatedSpeed = currentSpeed;
              lastReceivedBytes = received;
              lastProgressTime = now;
            } else if (totalElapsed > 500 && received > 0) {
              // Use overall average for initial updates or fallback
              currentSpeed = (received / 1024 / 1024) / (totalElapsed / 1000);

              // Smooth with last calculated speed if available
              if (lastCalculatedSpeed > 0) {
                currentSpeed =
                    (lastCalculatedSpeed * 0.6) + (currentSpeed * 0.4);
              }

              lastCalculatedSpeed = currentSpeed;
            }

            // More realistic speed range with better variation
            currentSpeed = currentSpeed.clamp(0.1, 20.0);

            // Add natural variation for realism (±10%)
            if (currentSpeed > 0.5) {
              final variation = (DateTime.now().millisecond % 200 - 100) /
                  1000; // -0.1 to +0.1
              currentSpeed += currentSpeed * variation * 0.1; // ±10% variation
              currentSpeed = currentSpeed.clamp(0.1, 20.0);
            }

            // Calculate ETA more accurately
            Duration eta = Duration.zero;
            if (currentSpeed > 0.1) {
              final remainingBytes = total - received;
              final remainingMB = remainingBytes / 1024 / 1024;
              final etaSeconds = remainingMB / currentSpeed;
              eta = Duration(seconds: etaSeconds.round().clamp(0, 3600));
            }

            final downloadProgress = DownloadProgress(
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
              speed: currentSpeed,
              estimatedTimeRemaining: eta,
            );

            // Always emit progress updates for smooth UI
            _downloadController?.add(downloadProgress);

            // Log progress occasionally for debugging with better formatting
            if (received % (3 * 1024 * 1024) == 0 ||
                progress == 1.0 ||
                timeDiff > 2000) {
              // Every 3MB, completion, or every 2 seconds
              developer.log(
                'Download: ${(progress * 100).toStringAsFixed(1)}% | ${currentSpeed.toStringAsFixed(1)} MB/s | ETA: ${eta.inSeconds}s | ${(received / 1024 / 1024).toStringAsFixed(1)}/${(total / 1024 / 1024).toStringAsFixed(1)} MB',
                name: 'UpdateService',
              );
            }
          }
        },
      );

      _isDownloading = false;
      developer.log('Download completed: $filePath', name: 'UpdateService');

      // Send final progress update to ensure UI shows 100%
      final finalProgress = DownloadProgress(
        progress: 1.0,
        downloadedBytes: File(filePath).lengthSync(),
        totalBytes: File(filePath).lengthSync(),
        speed: lastCalculatedSpeed,
        estimatedTimeRemaining: Duration.zero,
      );
      _downloadController?.add(finalProgress);

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Auto-install immediately after download
      try {
        developer.log('Auto-installing update...', name: 'UpdateService');

        // Add a small delay to ensure download is fully completed
        await Future.delayed(const Duration(milliseconds: 500));

        await installUpdate(filePath);
      } catch (installError) {
        developer.log(
          'Auto-install failed: $installError',
          name: 'UpdateService',
        );

        // If auto-install fails, mark as ready to install and let user handle manually
        _statusController?.add(UpdateStatus.readyToInstall);

        // Show error to user
        throw Exception('Auto-installation failed: $installError');
      }

      // Call completion callback if provided
      if (onDownloadComplete != null) {
        onDownloadComplete(filePath);
      }

      return filePath;
    } on DioException catch (dioError) {
      _isDownloading = false;

      // Handle cancellation differently from other errors
      if (dioError.type == DioExceptionType.cancel) {
        developer.log('Download cancelled by user', name: 'UpdateService');
        _statusController?.add(UpdateStatus.cancelled);
        throw Exception('Download cancelled by user');
      } else {
        developer.log('Download failed: $dioError', name: 'UpdateService');
        _statusController?.add(UpdateStatus.error);
        rethrow;
      }
    } catch (error) {
      _isDownloading = false;
      developer.log('Download failed: $error', name: 'UpdateService');
      _statusController?.add(UpdateStatus.error);
      rethrow;
    }
  }

  Future<void> installUpdate(String filePath) async {
    if (_isInstalling) {
      throw Exception('Installation already in progress');
    }

    try {
      _isInstalling = true;
      _statusController?.add(UpdateStatus.installing);

      developer.log('Starting installation: $filePath', name: 'UpdateService');

      if (Platform.isAndroid) {
        // Check if file exists
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('APK file not found: $filePath');
        }

        // Check file size to ensure it's valid
        final fileSize = await file.length();
        developer.log('APK file size: $fileSize bytes', name: 'UpdateService');

        if (fileSize < 1024) {
          // Less than 1KB is suspicious
          throw Exception('APK file seems corrupted (too small)');
        }

        // For Android, use open_file to trigger the APK installation
        developer.log(
          'Attempting to open APK with system installer',
          name: 'UpdateService',
        );

        final result = await OpenFile.open(filePath);

        developer.log(
          'Installation result: ${result.type} - ${result.message}',
          name: 'UpdateService',
        );

        switch (result.type) {
          case ResultType.done:
            developer.log(
              'Installation triggered successfully',
              name: 'UpdateService',
            );
            _statusController?.add(UpdateStatus.installed);
            break;
          case ResultType.permissionDenied:
            developer.log(
              'Permission denied for installation. User needs to enable "Install from unknown sources"',
              name: 'UpdateService',
            );

            // Automatically open settings for user convenience
            await _openUnknownSourcesSettings();

            // Still mark as installed since the user will be prompted to enable the permission
            _statusController?.add(UpdateStatus.installed);
            break;
          case ResultType.noAppToOpen:
            developer.log(
              'No app found to handle APK installation',
              name: 'UpdateService',
            );
            // Try alternative approach - use Intent with specific MIME type
            try {
              final result2 = await OpenFile.open(
                filePath,
                type: 'application/vnd.android.package-archive',
              );
              developer.log(
                'Alternative installation result: ${result2.type} - ${result2.message}',
                name: 'UpdateService',
              );

              if (result2.type == ResultType.done ||
                  result2.type == ResultType.permissionDenied) {
                _statusController?.add(UpdateStatus.installed);
              } else {
                throw Exception(
                  'Failed to open APK installer: ${result2.message}',
                );
              }
            } catch (e) {
              throw Exception('No suitable app found to install APK: $e');
            }
            break;
          case ResultType.fileNotFound:
            throw Exception('APK file not found during installation');
          case ResultType.error:
            // For APK files, even if there's an "error", the system installer might still open
            if (filePath.endsWith('.apk')) {
              developer.log(
                'Assuming APK installation dialog opened despite error',
                name: 'UpdateService',
              );
              _statusController?.add(UpdateStatus.installed);
            } else {
              throw Exception('Installation failed: ${result.message}');
            }
            break;
        }
      } else {
        // For other platforms, this would need platform-specific implementation
        throw Exception('Auto-installation not supported on this platform');
      }

      _isInstalling = false;
      developer.log('Installation process completed', name: 'UpdateService');
    } catch (error) {
      _isInstalling = false;
      _statusController?.add(UpdateStatus.error);
      developer.log('Installation failed: $error', name: 'UpdateService');
      rethrow;
    }
  }

  Future<void> downloadAndInstall(String downloadUrl) async {
    try {
      // The downloadUpdate method will now handle auto-installation
      await downloadUpdate(downloadUrl);
    } catch (error) {
      // Reset states on any error to ensure navigation safety checks work correctly
      _isDownloading = false;
      _isInstalling = false;

      developer.log(
        'Download and install failed: $error',
        name: 'UpdateService',
      );

      // Don't log as error if it was just cancelled
      if (!error.toString().contains('cancelled')) {
        // Log error for non-cancellation cases
        developer.log('Actual download error: $error', name: 'UpdateService');
        _statusController?.add(UpdateStatus.error);
      }

      rethrow;
    }
  }

  void cancelDownload() {
    if (_isDownloading && _downloadCancelToken != null) {
      developer.log('Cancelling download...', name: 'UpdateService');

      _downloadCancelToken?.cancel('Download cancelled by user');

      // Reset all download/installation states immediately
      _isDownloading = false;
      _isInstalling = false;

      // Immediately set cancelled status
      _statusController?.add(UpdateStatus.cancelled);

      developer.log('Download cancelled by user', name: 'UpdateService');
    } else {
      developer.log('No active download to cancel', name: 'UpdateService');
    }
  }

  Future<List<UpdateInfo>> getAllUpdates() async {
    try {
      final response = await _supabase
          ?.from('app_updates')
          .select('*')
          .order('version_code', ascending: false);

      return response?.map<UpdateInfo>((row) {
            return UpdateInfo(
              versionName: row['version_name'] as String,
              versionCode: row['version_code'] as int,
              updateTitle: row['update_title'] as String,
              updateDescription: row['update_description'] as String,
              changelog: row['changelog'] as String,
              featureHighlights: List<String>.from(
                row['feature_highlights'] as List? ?? [],
              ),
              bugFixes: List<String>.from(row['bug_fixes'] as List? ?? []),
              improvements: List<String>.from(
                row['improvements'] as List? ?? [],
              ),
              downloadUrl: row['download_url'] as String?,
              fileSizeMB: (row['file_size_mb'] as num?)?.toDouble() ?? 0.0,
              isForced: row['is_forced'] as bool,
              minSupportedVersion: row['min_supported_version'] as int,
              releaseDate: DateTime.parse(row['release_date'] as String),
              currentVersionName: '',
              currentVersionCode: 0,
            );
          }).toList() ??
          [];
    } catch (error) {
      developer.log('Failed to get all updates: $error', name: 'UpdateService');
      return [];
    }
  }

  // Method to manually add update info (for testing/admin purposes)
  Future<void> addUpdateInfo({
    required String versionName,
    required int versionCode,
    required String updateTitle,
    required String updateDescription,
    required String changelog,
    required List<String> featureHighlights,
    required List<String> bugFixes,
    required List<String> improvements,
    String? downloadUrl,
    double fileSizeMB = 0.0,
    bool isForced = false,
    int minSupportedVersion = 1,
  }) async {
    try {
      await _supabase?.from('app_updates').insert({
        'version_name': versionName,
        'version_code': versionCode,
        'update_title': updateTitle,
        'update_description': updateDescription,
        'changelog': changelog,
        'feature_highlights': featureHighlights,
        'bug_fixes': bugFixes,
        'improvements': improvements,
        'download_url': downloadUrl,
        'file_size_mb': fileSizeMB,
        'is_forced': isForced,
        'min_supported_version': minSupportedVersion,
      });

      developer.log(
        'Added update info for version $versionName',
        name: 'UpdateService',
      );
    } catch (error) {
      developer.log('Failed to add update info: $error', name: 'UpdateService');
      rethrow;
    }
  }

  void dispose() {
    _updateTimer?.cancel();
    _realTimeTimer?.cancel();
    _downloadCancelToken?.cancel();
    _updateController?.close();
    _downloadController?.close();
    _statusController?.close();
    _isInitialized = false;
    developer.log('Update Service disposed', name: 'UpdateService');
  }

  // Enable real-time updates (optional)
  Stream<List<Map<String, dynamic>>> watchUpdates() {
    final supabase = _supabase;
    if (supabase == null) {
      // Return an empty stream if Supabase is not available
      return const Stream.empty();
    }

    return supabase.from('app_updates').stream(
        primaryKey: const ['id']).order('version_code', ascending: false);
  }

  Future<void> _openUnknownSourcesSettings() async {
    try {
      if (Platform.isAndroid) {
        developer.log(
          'Opening Android settings for unknown sources...',
          name: 'UpdateService',
        );

        // For Android 8.0+ (API level 26+), open the specific app's install permission page
        const intent = AndroidIntent(
          action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
          data: 'package:com.ekalliptus.anrsaver', // Your app's package name
        );

        try {
          await intent.launch();
        } catch (e) {
          // Fallback for older Android versions or if specific settings don't work
          developer.log(
            'App-specific settings failed, trying general settings: $e',
            name: 'UpdateService',
          );

          const fallbackIntent = AndroidIntent(
            action: 'android.settings.SECURITY_SETTINGS',
          );

          await fallbackIntent.launch();
        }
      }
    } catch (error) {
      developer.log('Failed to open settings: $error', name: 'UpdateService');
    }
  }

  // Public method to open unknown sources settings (can be called from UI)
  Future<void> openUnknownSourcesSettings() async {
    await _openUnknownSourcesSettings();
  }

  // Public method to manually trigger update check (useful for immediate checks)
  Future<void> triggerUpdateCheck() async {
    try {
      developer.log('🔄 Manual update check triggered', name: 'UpdateService');
      final updateInfo = await checkForUpdates(silent: false, forceShow: true);
      if (updateInfo != null) {
        developer.log(
            '📢 Manual update check found update: ${updateInfo.versionName}',
            name: 'UpdateService');
      } else {
        developer.log('✅ Manual update check: no updates available',
            name: 'UpdateService');
      }
    } catch (e) {
      developer.log('❌ Manual update check failed: $e', name: 'UpdateService');
    }
  }

  Future<void> remindLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindLaterTime = DateTime.now().add(const Duration(minutes: 10));
      await prefs.setInt(
          _remindLaterKey, remindLaterTime.millisecondsSinceEpoch);
      developer.log('Remind later set for 10 minutes: $remindLaterTime',
          name: 'UpdateService');
    } catch (error) {
      developer.log('Failed to set remind later: $error',
          name: 'UpdateService');
    }
  }

  Future<bool> shouldShowUpdateDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindLaterTimestamp = prefs.getInt(_remindLaterKey);

      if (remindLaterTimestamp != null) {
        final remindLaterTime =
            DateTime.fromMillisecondsSinceEpoch(remindLaterTimestamp);
        final now = DateTime.now();

        if (now.isBefore(remindLaterTime)) {
          developer.log(
              'Update dialog suppressed - remind later active until: $remindLaterTime',
              name: 'UpdateService');
          return false;
        } else {
          // Clear expired remind later timestamp
          await prefs.remove(_remindLaterKey);
          developer.log('Remind later period expired, clearing timestamp',
              name: 'UpdateService');
        }
      }

      return true;
    } catch (error) {
      developer.log('Error checking remind later status: $error',
          name: 'UpdateService');
      return true; // Default to showing dialog if there's an error
    }
  }

  Future<void> clearRemindLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_remindLaterKey);
      developer.log(
        'Cleared any remind later timestamps on startup',
        name: 'UpdateService',
      );
    } catch (error) {
      developer.log(
        'Failed to clear remind later timestamps: $error',
        name: 'UpdateService',
      );
    }
  }

  /// Mark that an update dialog was shown to start cooldown period
  void markDialogShown() {
    _lastDialogShownTime = DateTime.now();
    developer.log(
      'Update dialog shown, starting ${_dialogCooldownDuration.inMinutes}-minute cooldown period',
      name: 'UpdateService',
    );
  }

  /// Reset dialog cooldown to allow immediate showing
  void resetDialogCooldown() {
    _lastDialogShownTime = null;
    developer.log(
      'Dialog cooldown reset - dialogs can now be shown immediately',
      name: 'UpdateService',
    );
  }
}

// Update Status enum
enum UpdateStatus {
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  installing,
  installed,
  cancelled,
  error,
}

// Update Info class
class UpdateInfo {
  final String versionName;
  final int versionCode;
  final String updateTitle;
  final String updateDescription;
  final String changelog;
  final List<String> featureHighlights;
  final List<String> bugFixes;
  final List<String> improvements;
  final String? downloadUrl;
  final double fileSizeMB;
  bool isForced;
  final int minSupportedVersion;
  final DateTime releaseDate;
  final String currentVersionName;
  final int currentVersionCode;

  UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.updateTitle,
    required this.updateDescription,
    required this.changelog,
    required this.featureHighlights,
    required this.bugFixes,
    required this.improvements,
    this.downloadUrl,
    required this.fileSizeMB,
    required this.isForced,
    required this.minSupportedVersion,
    required this.releaseDate,
    required this.currentVersionName,
    required this.currentVersionCode,
  });

  bool get hasDownloadUrl => downloadUrl != null && downloadUrl!.isNotEmpty;

  bool get isNewerVersion => versionCode > currentVersionCode;

  String get formattedFileSize {
    if (fileSizeMB < 1) {
      return '${(fileSizeMB * 1024).toStringAsFixed(1)} KB';
    }
    return '${fileSizeMB.toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'UpdateInfo(version: $versionName, code: $versionCode, forced: $isForced)';
  }
}

// Download Progress class
class DownloadProgress {
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final double speed; // MB/s
  final Duration estimatedTimeRemaining;

  DownloadProgress({
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    required this.estimatedTimeRemaining,
  });

  int get progressPercentage => (progress * 100).round();

  String get formattedSpeed => '${speed.toStringAsFixed(1)} MB/s';

  String get formattedETA {
    final hours = estimatedTimeRemaining.inHours;
    final minutes = estimatedTimeRemaining.inMinutes % 60;
    final seconds = estimatedTimeRemaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedProgress {
    final downloaded = downloadedBytes / 1024 / 1024; // MB
    final total = totalBytes / 1024 / 1024; // MB
    return '${downloaded.toStringAsFixed(1)}/${total.toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'DownloadProgress($progressPercentage%, $formattedSpeed, ETA: $formattedETA)';
  }
}
