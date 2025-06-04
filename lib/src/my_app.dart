import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/config/routes_manager.dart';
import 'package:anr_saver/src/container_injector.dart';
import 'package:anr_saver/src/core/utils/app_strings.dart';
import 'package:anr_saver/src/core/services/update_service.dart';
import 'package:anr_saver/src/core/widgets/update_dialog.dart';
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

  @override
  void initState() {
    super.initState();

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
      await _updateService.triggerUpdateCheck();
    } catch (e) {
      developer.log('❌ Failed to setup update listeners: $e', name: 'MyApp');
      // Don't rethrow - let the app continue without update listeners
    }
  }

  void _handleUpdateDetected(UpdateInfo updateInfo) {
    // Atomic check and operation to prevent any race conditions
    if (_isDialogOperationInProgress ||
        _isUpdateDialogShowing ||
        _dialogWasShown) {
      developer.log(
          '⚠️ Dialog operation already in progress or completed, ignoring new update',
          name: 'MyApp');
      return;
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
    if (_isDialogOperationInProgress ||
        _isUpdateDialogShowing ||
        _dialogWasShown) {
      return;
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
            if (mounted && !_isUpdateDialogShowing && !_dialogWasShown) {
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
    // Final atomic check before showing dialog
    if (_isUpdateDialogShowing || _dialogWasShown) {
      developer.log('⚠️ Update dialog already showing or was shown, aborting',
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

    // Check if widget is still mounted before showing dialog
    if (!mounted) {
      _isUpdateDialogShowing = false;
      developer.log('⚠️ Widget not mounted, cannot show update dialog',
          name: 'MyApp');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        updateService: _updateService,
      ),
    ).then((_) {
      _isUpdateDialogShowing = false;
      developer.log('🎬 Update dialog closed', name: 'MyApp');
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
    if (_dialogWasShown && !_isUpdateDialogShowing) {
      _dialogWasShown = false;
      developer.log('🔄 Reset dialog state for main app transition',
          name: 'MyApp');
    }
  }

  @override
  void dispose() {
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
            developer.log('🎨 Creating AdaptiveTheme...', name: 'MyApp');

            return AdaptiveTheme(
              light: ThemeState.lightTheme.themeData,
              dark: ThemeState.darkTheme.themeData,
              debugShowFloatingThemeButton: false,
              initial: AdaptiveThemeMode.system,
              builder: (theme, darkTheme) {
                developer.log('🌈 AdaptiveTheme builder called', name: 'MyApp');

                try {
                  developer.log('🧱 Creating MultiBlocProvider...',
                      name: 'MyApp');

                  return MultiBlocProvider(
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
                    child: BlocBuilder<ThemeBloc, ThemeState>(
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
                            theme: theme,
                            darkTheme: darkTheme,
                            initialRoute: Routes.splash,
                            onGenerateRoute: (settings) {
                              developer.log(
                                  '🛣️ Generating route for: ${settings.name}',
                                  name: 'MyApp');

                              // Check for pending update after route change
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _checkPendingUpdate();

                                // Special handling for downloader route - only if no dialog was shown yet
                                if (settings.name == '/downloader') {
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
            developer.log('❌ Error creating AdaptiveTheme: $e', name: 'MyApp');
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

  // Helper method to get current route more robustly
  String? _getCurrentRoute() {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return null;

      // Try to get the current route name from ModalRoute
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        final routeName = route!.settings.name;
        developer.log('🛣️ Route detection - found route: $routeName',
            name: 'MyApp');
        return routeName;
      }

      // Secondary method: try to get route from Navigator
      try {
        final navigator = Navigator.of(context);

        // Check if we have any routes
        if (navigator.canPop()) {
          // Try to inspect the current route more carefully
          // If we're here, we definitely have multiple routes in stack

          // For now, let's be more conservative and only assume downloader
          // if we've been running for a while (indicating we're past initial setup)
          final now = DateTime.now();
          if (_appStartTime != null) {
            final timeSinceStart = now.difference(_appStartTime!);
            if (timeSinceStart.inSeconds > 20) {
              developer.log(
                  '🛣️ Route detection - can pop + time based, assuming downloader',
                  name: 'MyApp');
              return '/downloader';
            } else {
              developer.log(
                  '🛣️ Route detection - can pop but too early, might be permission setup',
                  name: 'MyApp');
              return '/permissionSetup'; // Conservative assumption during early app lifecycle
            }
          }

          developer.log(
              '🛣️ Route detection - can pop but no app start time, being conservative',
              name: 'MyApp');
          return null;
        } else {
          developer.log(
              '🛣️ Route detection - cannot pop, likely on initial route',
              name: 'MyApp');
          return '/splash'; // Likely on splash or initial route
        }
      } catch (e) {
        developer.log('🛣️ Route detection - navigator error: $e',
            name: 'MyApp');
        return null;
      }
    } catch (e) {
      developer.log('⚠️ Error in _getCurrentRoute: $e', name: 'MyApp');
      return null;
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

      // Get current route first
      final currentRoute = _getCurrentRoute();

      // Explicitly check for permission setup route - never safe during permission setup
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

      // More conservative fallback checks
      final navigator = Navigator.of(context);
      final canPop = navigator.canPop();

      // Enhanced time-based check - but only if we're certain we're not in permission setup
      final now = DateTime.now();
      if (_appStartTime != null &&
          currentRoute != '/permissionSetup' &&
          currentRoute != '/splash') {
        final timeSinceStart = now.difference(_appStartTime!);

        // Only use time-based fallback if enough time has passed AND we can pop
        // This indicates we're likely past the initial setup phase
        if (timeSinceStart.inSeconds > 25 && canPop) {
          developer.log(
              '🟡 Safe to show dialog: time-based fallback (${timeSinceStart.inSeconds}s since start + canPop), route: $currentRoute',
              name: 'MyApp');
          return true;
        }
      }

      developer.log(
          '🔴 Not safe to show dialog: canPop=$canPop, route=$currentRoute, conservative approach',
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

        // Be more aggressive on later attempts
        if (isSafe || (i >= 3 && _pendingUpdateInfo != null)) {
          final updateInfo = _pendingUpdateInfo!;
          _clearPendingUpdate();

          developer.log(
              '✅ Showing pending update dialog after retry ${i + 1} (aggressive: ${i >= 3})',
              name: 'MyApp');

          _showUpdateDialogAtomic(updateInfo);
          return; // Stop further retries
        }
      });
      _activeTimers.add(timer);
    }

    // Final fallback: Force show after 30 seconds regardless of safety check
    final forceTimer = Timer(const Duration(seconds: 30), () {
      // Check if retry is still needed
      if (!mounted ||
          _pendingUpdateInfo == null ||
          _isUpdateDialogShowing ||
          _dialogWasShown ||
          !_isRetryScheduled) {
        return;
      }

      developer.log('🚨 FORCE showing update dialog after 30s timeout',
          name: 'MyApp');
      final updateInfo = _pendingUpdateInfo!;
      _clearPendingUpdate();

      // Force show by directly calling showDialog without safety checks
      final context = navigatorKey.currentContext;
      if (context != null && mounted) {
        _isUpdateDialogShowing = true;
        _dialogWasShown = true;

        // ignore: use_build_context_synchronously
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: !updateInfo.isForced,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            updateService: _updateService,
          ),
        ).then((_) {
          _isUpdateDialogShowing = false;
          developer.log('🎬 Forced update dialog closed', name: 'MyApp');
        });
      }
    });
    _activeTimers.add(forceTimer);
  }
}
