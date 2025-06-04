import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:anr_saver/src/config/routes_manager.dart';
import 'package:anr_saver/src/container_injector.dart';
import 'package:anr_saver/src/core/utils/app_strings.dart';
import 'package:anr_saver/src/core/services/update_service.dart';
import 'package:anr_saver/src/core/widgets/update_dialog.dart';
import 'package:anr_saver/src/core/providers/language_provider.dart';
import 'package:anr_saver/src/features/social_videos_downloader/presentation/bloc/downloader_bloc/downloader_bloc.dart';
import 'package:anr_saver/src/features/social_videos_downloader/presentation/bloc/theme_bloc/theme_bloc.dart';
import 'dart:async';
import 'dart:developer' as developer;

// Global navigator key for dialog access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // Static method to mark permission setup as completed
  static void markPermissionSetupCompleted() {
    _MyAppState._instance?._setPermissionSetupCompleted();
  }

  // Static method to trigger update check for debugging
  static void triggerUpdateCheck() {
    _MyAppState._instance?._triggerManualUpdateCheck();
  }
}

class _MyAppState extends State<MyApp> {
  late UpdateService _updateService;
  StreamSubscription<UpdateInfo>? _updateSubscription;
  bool _isUpdateDialogShowing = false;
  UpdateInfo? _pendingUpdateInfo; // Store pending update info
  DateTime? _appStartTime;
  bool _isRetryScheduled = false; // Prevent multiple retry schedules

  // Additional atomic flags for comprehensive prevention
  bool _isDialogOperationInProgress = false;
  final List<Timer> _activeTimers = []; // Track all active timers
  bool _dialogWasShown = false; // Track if dialog was ever shown
  bool _permissionSetupCompleted =
      false; // Track if permission setup is completed

  // Static accessor for permission completion
  static _MyAppState? _instance;

  void _setPermissionSetupCompleted() {
    _permissionSetupCompleted = true;
    _lastDetectedRoute =
        '/downloader'; // Clear route cache to force re-detection
    _lastRouteDetectionTime = null;
    developer.log(
        '✅ Permission setup marked as completed! Clearing route cache.',
        name: 'MyApp');

    // Check for pending updates immediately
    if (_pendingUpdateInfo != null) {
      developer.log('🔄 Checking pending update after permission completion',
          name: 'MyApp');
      _checkPendingUpdate();
    }
  }

  void _triggerManualUpdateCheck() {
    developer.log('🔄 Manual update check triggered from external call',
        name: 'MyApp');

    // Reset dialog state to allow new dialog
    _dialogWasShown = false;
    _updateService.resetDialogCooldown();

    // Trigger immediate update check
    _updateService.triggerUpdateCheck();
  }

  @override
  void initState() {
    super.initState();
    _instance = this; // Set static instance reference

    developer.log('🎯 MyApp initState called', name: 'MyApp');

    _updateService = sl<UpdateService>();

    // Setup update listener with delay to ensure UpdateService is ready
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _setupUpdateListener();
      }
    });

    _appStartTime = DateTime.now();
  }

  void _setupUpdateListener() async {
    try {
      developer.log('🔧 Setting up update listener...', name: 'MyApp');

      // Check if update service and its stream are available
      final updateStream = _updateService.updateStream;
      if (updateStream == null) {
        developer.log(
            '⚠️ UpdateService stream is null, retrying in 3 seconds...',
            name: 'MyApp');

        // Retry after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _setupUpdateListener();
          }
        });
        return;
      }

      _updateSubscription = updateStream.listen(
        (updateInfo) {
          if (mounted) {
            developer.log(
                '🚨 Update detected in listener: ${updateInfo.versionName}',
                name: 'MyApp');
            _handleUpdateDetected(updateInfo);
          }
        },
        onError: (error) {
          developer.log('Error in update stream: $error', name: 'MyApp');
        },
      );

      developer.log('✅ Update listener setup completed successfully',
          name: 'MyApp');

      // Also trigger immediate update check
      _updateService.triggerUpdateCheck();
    } catch (e) {
      developer.log('❌ Failed to setup update listeners: $e', name: 'MyApp');
      // Don't rethrow - let the app continue without update listeners
    }
  }

  void _handleUpdateDetected(UpdateInfo updateInfo) {
    // Add debug logging for fresh install detection
    final timeSinceStart =
        DateTime.now().difference(_appStartTime ?? DateTime.now());
    final isFreshInstall = timeSinceStart.inMinutes < 2;

    developer.log(
        '🔍 Update detected: ${updateInfo.versionName} | '
        'TimeSinceStart: ${timeSinceStart.inMinutes}min | '
        'IsFreshInstall: $isFreshInstall | '
        'DialogWasShown: $_dialogWasShown | '
        'OperationInProgress: $_isDialogOperationInProgress',
        name: 'MyApp');

    // Atomic check and operation to prevent any race conditions
    if (_isDialogOperationInProgress || _isUpdateDialogShowing) {
      developer.log(
          '⚠️ Dialog operation already in progress, ignoring new update',
          name: 'MyApp');
      return;
    }

    // For fresh installs, skip all cooldown checks and show immediately if safe
    if (isFreshInstall) {
      developer.log('🆕 Fresh install detected - bypassing cooldown checks',
          name: 'MyApp');
      // For fresh installs, reset dialog flag to allow showing
      _dialogWasShown = false;
    } else {
      // For regular operation, check cooldown period
      if (_dialogWasShown) {
        final timeSinceLastDialog =
            DateTime.now().difference(_appStartTime ?? DateTime.now());
        if (timeSinceLastDialog.inMinutes < 10) {
          developer.log(
              '⏰ Real-time update ignored - dialog shown recently (${timeSinceLastDialog.inMinutes} min ago)',
              name: 'MyApp');
          return;
        } else {
          // Reset flag to allow new dialog
          _dialogWasShown = false;
          developer.log('✅ Cooldown period passed, allowing new update dialog',
              name: 'MyApp');
        }
      }
    }

    _isDialogOperationInProgress = true;

    try {
      // Use the more robust route detection
      final currentRoute = _getCurrentRoute();
      final isSafe = _isSafeToShowUpdateDialog();

      developer.log(
          '🛣️ Update detected while on route: $currentRoute, safe: $isSafe',
          name: 'MyApp');

      // Check if we're in a safe state to show the dialog
      if (!isSafe) {
        developer.log(
            '⏳ Delaying update dialog, not in safe state. Route: $currentRoute',
            name: 'MyApp');
        _pendingUpdateInfo = updateInfo;

        // Set multiple retry timers with increasing delays - but only if not already scheduled
        if (!_isRetryScheduled) {
          _scheduleRetryUpdates();
        }
        return;
      }

      _showUpdateDialogAtomic(updateInfo);
    } finally {
      _isDialogOperationInProgress = false;
    }
  }

  void _checkPendingUpdate() {
    // Atomic check to prevent concurrent operations
    if (_isDialogOperationInProgress || _isUpdateDialogShowing) {
      return;
    }

    // For fresh installs or after cooldown, allow pending updates to show
    if (_dialogWasShown) {
      final timeSinceStart =
          DateTime.now().difference(_appStartTime ?? DateTime.now());
      // Only block if dialog was shown recently AND app has been running for a while
      if (timeSinceStart.inMinutes > 2) {
        final timeSinceLastDialog =
            DateTime.now().difference(_appStartTime ?? DateTime.now());
        if (timeSinceLastDialog.inMinutes < 10) {
          developer.log(
              '⏰ Pending update ignored - dialog shown recently, in cooldown period',
              name: 'MyApp');
          return;
        }
      }
    }

    // Check for pending update after route change
    if (_pendingUpdateInfo != null && mounted) {
      _isDialogOperationInProgress = true;

      try {
        final currentRoute = _getCurrentRoute();
        final isSafe = _isSafeToShowUpdateDialog();

        developer.log(
            '🔄 Checking pending update - route: $currentRoute, safe: $isSafe',
            name: 'MyApp');

        if (isSafe) {
          developer.log(
              '✅ Showing pending update dialog after route change to: $currentRoute',
              name: 'MyApp');
          final updateInfo = _pendingUpdateInfo!;
          _clearPendingUpdate();

          // Add a small delay to ensure the route transition is complete
          final timer = Timer(const Duration(milliseconds: 800), () {
            if (mounted && !_isUpdateDialogShowing) {
              // Allow pending updates to show regardless of _dialogWasShown
              // because we already checked cooldown above
              _showUpdateDialogAtomic(updateInfo);
            }
          });
          _activeTimers.add(timer);
        } else {
          developer.log('⏳ Still not safe to show dialog. Route: $currentRoute',
              name: 'MyApp');
        }
      } finally {
        _isDialogOperationInProgress = false;
      }
    }
  }

  void _showUpdateDialogAtomic(UpdateInfo updateInfo) {
    // Check fresh install status for final decision
    final timeSinceStart =
        DateTime.now().difference(_appStartTime ?? DateTime.now());
    final isFreshInstall = timeSinceStart.inMinutes < 2;

    developer.log(
        '🎬 Attempting to show dialog: ${updateInfo.versionName} | '
        'IsFreshInstall: $isFreshInstall | '
        'DialogWasShown: $_dialogWasShown | '
        'IsShowing: $_isUpdateDialogShowing',
        name: 'MyApp');

    // Final atomic check before showing dialog
    if (_isUpdateDialogShowing) {
      developer.log('⚠️ Update dialog already showing, aborting',
          name: 'MyApp');
      return;
    }

    // For fresh installs, always allow dialog to show
    if (!isFreshInstall && _dialogWasShown) {
      developer.log(
          '⚠️ Update dialog was already shown and not fresh install, aborting',
          name: 'MyApp');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      developer.log('⚠️ Cannot show update dialog: no context available',
          name: 'MyApp');
      return;
    }

    // Use robust route detection and safety check
    final currentRoute = _getCurrentRoute();
    final isSafe = _isSafeToShowUpdateDialog();

    developer.log(
        '🛣️ Attempting to show update dialog - route: $currentRoute, safe: $isSafe',
        name: 'MyApp');

    // If not safe, store as pending and schedule retries
    if (!isSafe) {
      developer.log(
          '⚠️ Delaying update dialog - not safe to show. Route: $currentRoute',
          name: 'MyApp');
      _pendingUpdateInfo = updateInfo;
      _scheduleRetryUpdates();
      return;
    }

    // Mark dialog as showing and clear all pending operations
    _isUpdateDialogShowing = true;
    _dialogWasShown = true;
    _clearPendingUpdate();
    _cancelAllTimers();

    developer.log('🎬 Showing update dialog for: ${updateInfo.versionName}',
        name: 'MyApp');

    // Mark dialog as shown to start cooldown period
    _updateService.markDialogShown();

    // Check if widget is still mounted before showing dialog
    if (!mounted) {
      _isUpdateDialogShowing = false;
      developer.log('⚠️ Widget not mounted, cannot show update dialog',
          name: 'MyApp');
      return;
    }

    // Show dialog immediately for fresh installs, with delay for others
    final delayDuration = isFreshInstall
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 1000);

    Future.delayed(delayDuration, () {
      if (!mounted) {
        _isUpdateDialogShowing = false;
        return;
      }

      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        developer.log('❌ No valid context for dialog', name: 'MyApp');
        _isUpdateDialogShowing = false;
        return;
      }

      try {
        showDialog(
          context: ctx,
          barrierDismissible: !updateInfo.isForced,
          useRootNavigator: true,
          builder: (dialogContext) => PopScope(
            canPop: !updateInfo.isForced,
            child: UpdateDialog(
              updateInfo: updateInfo,
              updateService: _updateService,
            ),
          ),
        ).then((_) {
          _isUpdateDialogShowing = false;
          developer.log('🎬 Update dialog closed', name: 'MyApp');
        }).catchError((error) {
          _isUpdateDialogShowing = false;
          developer.log('❌ Update dialog error: $error', name: 'MyApp');
        });
      } catch (e) {
        _isUpdateDialogShowing = false;
        developer.log('❌ Failed to show dialog: $e', name: 'MyApp');
      }
    });
  }

  void _clearPendingUpdate() {
    _pendingUpdateInfo = null;
    _isRetryScheduled = false;
  }

  void _cancelAllTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    developer.log('🧹 Cancelled ${_activeTimers.length} active timers',
        name: 'MyApp');
  }

  void _resetDialogStateForMainApp() {
    // Reset dialog state when we know we're transitioning to main app
    // This allows update dialogs to be shown again after permission setup
    _dialogWasShown = false;

    // Also reset the cooldown to allow immediate showing after permission setup
    _updateService.resetDialogCooldown();

    developer.log('🔄 Reset dialog state and cooldown for main app transition',
        name: 'MyApp');
  }

  @override
  void dispose() {
    // Clear static instance reference
    if (_instance == this) {
      _instance = null;
    }

    _updateSubscription?.cancel();
    _cancelAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🏗️ MyApp build called - initialRoute: ${Routes.splash}',
        name: 'MyApp');

    try {
      developer.log('🔧 Creating DevicePreview...', name: 'MyApp');

      return DevicePreview(
        enabled: false, // Disable device preview for production
        builder: (context) {
          developer.log('📱 DevicePreview builder called', name: 'MyApp');

          try {
            developer.log('🧱 Creating MultiBlocProvider...', name: 'MyApp');

            return ChangeNotifierProvider<LanguageProvider>(
              create: (context) {
                developer.log('🌐 Creating LanguageProvider', name: 'MyApp');
                return LanguageProvider();
              },
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<DownloaderBloc>(
                    create: (context) {
                      developer.log('⬇️ Creating DownloaderBloc',
                          name: 'MyApp');
                      return sl<DownloaderBloc>();
                    },
                  ),
                  BlocProvider<ThemeBloc>(
                    create: (context) {
                      developer.log('🎭 Creating ThemeBloc', name: 'MyApp');
                      return sl<ThemeBloc>();
                    },
                  ),
                ],
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, child) {
                    return BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, state) {
                        developer.log(
                            '🎨 Building MaterialApp with initialRoute: ${Routes.splash}',
                            name: 'MyApp');
                        developer.log(
                            '🎭 ThemeBloc state: ${state.runtimeType}',
                            name: 'MyApp');

                        try {
                          final app = MaterialApp(
                            navigatorKey: navigatorKey,
                            title: AppStrings.appName,
                            debugShowCheckedModeBanner: false,
                            theme: state.themeData,
                            darkTheme: ThemeState.darkTheme.themeData,
                            themeMode:
                                state.themeData.brightness == Brightness.dark
                                    ? ThemeMode.dark
                                    : ThemeMode.light,
                            initialRoute: Routes.splash,
                            onGenerateRoute: (settings) {
                              developer.log(
                                  '🛣️ Generating route for: ${settings.name}',
                                  name: 'MyApp');

                              // Check for pending update after route change
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                // Clear route cache when route changes
                                _lastDetectedRoute = settings.name;
                                _lastRouteDetectionTime = DateTime.now();

                                _checkPendingUpdate();

                                // Special handling for downloader route - only if no dialog was shown yet
                                if (settings.name == '/downloader') {
                                  // Mark permission setup as completed when we reach downloader
                                  _setPermissionSetupCompleted();

                                  // Reset dialog state when transitioning to main app
                                  _resetDialogStateForMainApp();

                                  if (!_dialogWasShown) {
                                    _scheduleDownloaderRouteChecks();
                                  }
                                }
                              });

                              return AppRounter.getRoute(settings);
                            },
                          );

                          developer.log('✅ MaterialApp created successfully',
                              name: 'MyApp');
                          return app;
                        } catch (e) {
                          developer.log('❌ Error creating MaterialApp: $e',
                              name: 'MyApp');
                          rethrow;
                        }
                      },
                    );
                  },
                ),
              ),
            );
          } catch (e) {
            developer.log('❌ Error creating MultiBlocProvider: $e',
                name: 'MyApp');
            rethrow;
          }
        },
      );
    } catch (e) {
      developer.log('❌ Error in MyApp build: $e', name: 'MyApp');
      rethrow;
    }
  }

  void _scheduleDownloaderRouteChecks() {
    // Trigger additional update checks with longer delays for downloader route
    final timer1 = Timer(const Duration(seconds: 2), () {
      if (mounted &&
          _pendingUpdateInfo != null &&
          !_isUpdateDialogShowing &&
          !_dialogWasShown) {
        developer.log('🔄 Special downloader route update check',
            name: 'MyApp');
        final updateInfo = _pendingUpdateInfo!;
        _clearPendingUpdate();
        _showUpdateDialogAtomic(updateInfo);
      }
    });

    final timer2 = Timer(const Duration(seconds: 5), () {
      if (mounted &&
          _pendingUpdateInfo != null &&
          !_isUpdateDialogShowing &&
          !_dialogWasShown) {
        developer.log('🔄 Final fallback downloader route update check',
            name: 'MyApp');
        final updateInfo = _pendingUpdateInfo!;
        _clearPendingUpdate();
        _showUpdateDialogAtomic(updateInfo);
      }
    });

    _activeTimers.addAll([timer1, timer2]);
  }

  // Current route cache to avoid repeated expensive calls
  String? _lastDetectedRoute;
  DateTime? _lastRouteDetectionTime;

  // Helper method to get current route more robustly
  String? _getCurrentRoute() {
    try {
      // Use cached result if recent (within 1 second)
      final now = DateTime.now();
      if (_lastRouteDetectionTime != null &&
          _lastDetectedRoute != null &&
          now.difference(_lastRouteDetectionTime!).inSeconds < 1) {
        return _lastDetectedRoute;
      }

      final context = navigatorKey.currentContext;
      if (context == null) return null;

      String? detectedRoute;

      // Try to get the current route name from ModalRoute
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        detectedRoute = route!.settings.name;
        developer.log('🛣️ Route detection - found route: $detectedRoute',
            name: 'MyApp');
      } else {
        // Fallback: Check if we know permission setup was completed
        if (_permissionSetupCompleted) {
          detectedRoute = '/downloader';
          developer.log(
              '🛣️ Route detection - using permission completion flag: /downloader',
              name: 'MyApp');
        } else {
          // Try time-based detection as last resort
          try {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              final now = DateTime.now();
              if (_appStartTime != null) {
                final timeSinceStart = now.difference(_appStartTime!);
                if (timeSinceStart.inSeconds > 20) {
                  detectedRoute = '/permissionSetup';
                  developer.log(
                      '🛣️ Route detection - can pop + time (${timeSinceStart.inSeconds}s), likely permission setup',
                      name: 'MyApp');
                } else {
                  detectedRoute = '/splash';
                  developer.log(
                      '🛣️ Route detection - can pop but early (${timeSinceStart.inSeconds}s), likely splash',
                      name: 'MyApp');
                }
              } else {
                detectedRoute = '/splash';
              }
            } else {
              detectedRoute = '/splash';
              developer.log(
                  '🛣️ Route detection - cannot pop, on initial route (splash)',
                  name: 'MyApp');
            }
          } catch (e) {
            developer.log('🛣️ Route detection - navigator error: $e',
                name: 'MyApp');
            detectedRoute = '/splash';
          }
        }
      }

      // Cache the result
      _lastDetectedRoute = detectedRoute;
      _lastRouteDetectionTime = now;

      return detectedRoute;
    } catch (e) {
      developer.log('⚠️ Error in _getCurrentRoute: $e', name: 'MyApp');
      return _lastDetectedRoute ?? '/splash';
    }
  }

  // Helper method to check if we're in a safe state to show update dialog
  bool _isSafeToShowUpdateDialog() {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        developer.log('🔴 Not safe: no context', name: 'MyApp');
        return false;
      }

      // Never show update dialog if permission setup hasn't been completed
      if (!_permissionSetupCompleted) {
        developer.log('🔴 Not safe: permission setup not completed yet',
            name: 'MyApp');
        return false;
      }

      // Check if update service is performing download/installation operations
      if (_updateService.isDownloading || _updateService.isInstalling) {
        developer.log('🔴 Not safe: download/installation in progress',
            name: 'MyApp');
        return false;
      }

      // Get current route first
      final currentRoute = _getCurrentRoute();

      // Explicitly check for permission setup route - NEVER safe during permission setup
      if (currentRoute == '/permissionSetup') {
        developer.log('🔴 Not safe: currently in permission setup',
            name: 'MyApp');
        return false;
      }

      // Check if we're on splash screen - also not safe
      if (currentRoute == '/splash' || currentRoute == '/') {
        developer.log('🔴 Not safe: on splash screen', name: 'MyApp');
        return false;
      }

      // Only consider it safe if we explicitly detect downloader route
      if (currentRoute == '/downloader') {
        developer.log('🟢 Safe to show dialog: explicitly on downloader route',
            name: 'MyApp');
        return true;
      }

      // If route is unknown/null, be extra conservative with time-based check
      final now = DateTime.now();
      if (_appStartTime != null && currentRoute == null) {
        final timeSinceStart = now.difference(_appStartTime!);

        // Only use time-based fallback if MUCH more time has passed
        // This ensures user has definitely completed permission setup
        if (timeSinceStart.inSeconds > 90) {
          developer.log(
              '🟡 Safe to show dialog: very long time fallback (${timeSinceStart.inSeconds}s since start)',
              name: 'MyApp');
          return true;
        }
      }

      developer.log(
          '🔴 Not safe to show dialog: route=$currentRoute, being conservative',
          name: 'MyApp');
      return false;
    } catch (e) {
      developer.log('⚠️ Error in _isSafeToShowUpdateDialog: $e', name: 'MyApp');
      return false;
    }
  }

  void _scheduleRetryUpdates() {
    // Prevent multiple scheduling
    if (_isRetryScheduled || _dialogWasShown) {
      developer.log('⚠️ Retry already scheduled or dialog was shown, skipping',
          name: 'MyApp');
      return;
    }

    _isRetryScheduled = true;
    developer.log(
        '🔄 Scheduling retry updates with ${[
          1,
          3,
          5,
          8,
          12,
          20
        ].length} attempts',
        name: 'MyApp');

    // Try multiple times with different delays to ensure the dialog shows
    final delays = [1, 3, 5, 8, 12, 20]; // More attempts with longer delays

    for (int i = 0; i < delays.length; i++) {
      final timer = Timer(Duration(seconds: delays[i]), () {
        // Check if retry is still needed
        if (!mounted ||
            _pendingUpdateInfo == null ||
            _isUpdateDialogShowing ||
            _dialogWasShown ||
            !_isRetryScheduled) {
          return;
        }

        final isSafe = _isSafeToShowUpdateDialog();
        final currentRoute = _getCurrentRoute();

        developer.log(
            '🔄 Retry attempt ${i + 1}/${delays.length}: safe=$isSafe, route=$currentRoute',
            name: 'MyApp');

        // Only show if truly safe - remove aggressive showing during permission setup
        if (isSafe) {
          final updateInfo = _pendingUpdateInfo!;
          _clearPendingUpdate();

          developer.log('✅ Showing pending update dialog after retry ${i + 1}',
              name: 'MyApp');

          _showUpdateDialogAtomic(updateInfo);
          return; // Stop further retries
        }
      });
      _activeTimers.add(timer);
    }

    // Note: Removed force timer to prevent bypass of safety checks during permission setup
  }
}
