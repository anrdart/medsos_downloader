// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:anr_saver/src/core/media_query.dart';
import 'package:anr_saver/src/core/utils/app_strings.dart';
import 'package:anr_saver/src/core/utils/styles_manager.dart';
import 'package:anr_saver/src/core/services/permission_service.dart';
import 'package:anr_saver/src/container_injector.dart';
import '../../config/routes_manager.dart';
import '../../core/utils/app_assets.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/preload_svg_assets.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final PermissionService _permissionService;
  bool _hasNavigated = false;

  @override
  initState() {
    super.initState();

    developer.log('SplashScreen initState called', name: 'SplashScreen');

    // Initialize permission service from dependency injection
    _permissionService = sl<PermissionService>();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.animationTime),
    );
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();

    // Start initialization process
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      developer.log('📱 Starting app initialization...', name: 'SplashScreen');

      // Run asset preloading in background to avoid blocking UI
      developer.log('🎨 Starting asset preloading...', name: 'SplashScreen');
      final preloadFuture = preloadAssets();

      // Wait minimum splash time while assets load
      developer.log('⏱️ Starting minimum splash time...', name: 'SplashScreen');
      final timeFuture = Future.delayed(
          const Duration(milliseconds: AppConstants.navigateTime));

      // Wait for both to complete, but don't block UI
      await Future.wait([preloadFuture, timeFuture]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log('⚠️ Asset preloading timed out, continuing anyway',
              name: 'SplashScreen');
          return [];
        },
      );

      developer.log('✅ Assets and timing completed', name: 'SplashScreen');

      // Add a safety net - if nothing navigates within 3 seconds, force navigate
      Timer(const Duration(seconds: 3), () {
        if (mounted && !_hasNavigated) {
          developer.log('🚨 Safety navigation triggered - going to main app',
              name: 'SplashScreen');
          _navigateToDownloader();
        }
      });

      // Check permissions and navigate accordingly
      developer.log('🔍 Starting permission check...', name: 'SplashScreen');
      await _checkPermissionsAndNavigate();
    } catch (e) {
      developer.log('❌ Error during app initialization: $e',
          name: 'SplashScreen');
      // Fallback to main screen even if there's an error
      if (!_hasNavigated) {
        _navigateToDownloader();
      }
    }
  }

  Future<void> _checkPermissionsAndNavigate() async {
    if (_hasNavigated) return;

    try {
      developer.log('🔐 Checking permissions...', name: 'SplashScreen');

      // Add timeout to permission checks to prevent hanging
      final result = await Future.any([
        Future.delayed(const Duration(seconds: 2), () => {'timeout': true}),
        _performPermissionCheck(),
      ]);

      if (_hasNavigated) return; // Exit if already navigated

      if (result['timeout'] == true) {
        developer.log('⏰ Permission check timed out, going to main app',
            name: 'SplashScreen');
        _navigateToDownloader();
        return;
      }

      // Process normal permission check result
      final isFirstLaunch = result['isFirstLaunch'] as bool;
      final permissionsGranted = result['permissionsGranted'] as bool;

      developer.log('📋 Is first launch: $isFirstLaunch', name: 'SplashScreen');
      developer.log('📋 Permissions granted: $permissionsGranted',
          name: 'SplashScreen');

      if (mounted && !_hasNavigated) {
        if (isFirstLaunch || !permissionsGranted) {
          developer.log(
              '🚪 First launch or permissions not granted, showing permission setup',
              name: 'SplashScreen');
          _navigateToPermissionSetup();
        } else {
          developer.log('✅ Permissions already granted, going to main app',
              name: 'SplashScreen');
          _navigateToDownloader();
        }
      } else {
        developer.log('⚠️ Widget not mounted or already navigated',
            name: 'SplashScreen');
      }
    } catch (e) {
      developer.log('❌ Error checking permissions: $e', name: 'SplashScreen');
      // If permission check fails, go to main app anyway
      if (!_hasNavigated) {
        _navigateToDownloader();
      }
    }
  }

  Future<Map<String, dynamic>> _performPermissionCheck() async {
    try {
      developer.log('🔍 Performing permission service check...',
          name: 'SplashScreen');

      // Check if this is first launch or permissions not granted
      final isFirstLaunch = await _permissionService.isFirstLaunch();
      developer.log('📋 First launch result: $isFirstLaunch',
          name: 'SplashScreen');

      final permissionsGranted =
          await _permissionService.areAllPermissionsGranted();
      developer.log('📋 Permissions result: $permissionsGranted',
          name: 'SplashScreen');

      return {
        'isFirstLaunch': isFirstLaunch,
        'permissionsGranted': permissionsGranted,
      };
    } catch (e) {
      developer.log('❌ Permission service error: $e', name: 'SplashScreen');
      // Return defaults that will navigate to main app
      return {
        'isFirstLaunch': false,
        'permissionsGranted': true,
      };
    }
  }

  Future preloadAssets() async {
    try {
      developer.log('🎨 Preloading assets...', name: 'SplashScreen');
      PreLoadAssets preLoadAssets = PreLoadAssets();
      await preLoadAssets.preLoadLoadingScreenAssets();
      developer.log('✅ Assets preloaded successfully', name: 'SplashScreen');
    } catch (e) {
      developer.log('⚠️ Asset preloading failed: $e', name: 'SplashScreen');
      // Continue anyway
    }
  }

  void _navigateToPermissionSetup() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      developer.log('Navigating to permission setup', name: 'SplashScreen');
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.permissionSetup,
        (route) => false,
      );
    }
  }

  void _navigateToDownloader() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      developer.log('Navigating to downloader', name: 'SplashScreen');
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.downloader,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0D), // Dark background to prevent white flash
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Container(
                  width: context.width * 0.5,
                  height: context.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        AppColors.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30),
                  child: const Image(
                    fit: BoxFit.contain,
                    image: AssetImage(AppAssets.splashLogo),
                  ),
                ),
              ),
              Positioned(
                bottom: context.height * 0.05,
                child: Column(
                  children: [
                    Text(
                      AppStrings.appName.toUpperCase(),
                      style: getTitleStyle(
                          fontSize: context.width * 0.06,
                          color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(AppStrings.appSlogan,
                        style: getRegularStyle(
                            fontSize: context.width * 0.035,
                            color: AppColors.white.withOpacity(0.8))),
                    const SizedBox(height: 20),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
