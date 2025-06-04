import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../features/social_videos_downloader/presentation/screens/downloader_screen.dart';
import '../features/social_videos_downloader/presentation/screens/downloads_screen.dart';
import '../features/social_videos_downloader/presentation/widgets/downloads_screen/view_video_screen.dart';
import '../features/splash/splash_screen.dart';
import '../core/screens/permission_setup_screen.dart';

class Routes {
  static const String splash = "/splash";
  static const String downloader = "/downloader";
  static const String downloads = "/downloads";
  static const String viewVideo = "/viewVideo";
  static const String permissionSetup = "/permissionSetup";
}

class AppRounter {
  static Route? getRoute(RouteSettings setting) {
    developer.log('🚀 AppRouter.getRoute called for: ${setting.name}',
        name: 'AppRouter');

    switch (setting.name) {
      case Routes.splash:
        developer.log('✅ Creating SplashScreen route', name: 'AppRouter');
        return MaterialPageRoute(builder: (context) {
          developer.log('🎬 SplashScreen widget builder called',
              name: 'AppRouter');
          return const SplashScreen();
        });
      case Routes.downloader:
        developer.log('✅ Creating DownloaderScreen route', name: 'AppRouter');
        return MaterialPageRoute(
            builder: (context) => const DownloaderScreen());
      case Routes.downloads:
        developer.log('✅ Creating DownloadsScreen route', name: 'AppRouter');
        return MaterialPageRoute(builder: (context) => const DownloadsScreen());
      case Routes.viewVideo:
        developer.log('✅ Creating ViewVideoScreen route', name: 'AppRouter');
        return MaterialPageRoute(
            builder: (context) => ViewVideoScreen(
                  videoPath: setting.arguments as String,
                ));
      case Routes.permissionSetup:
        developer.log('✅ Creating PermissionSetupScreen route',
            name: 'AppRouter');
        return MaterialPageRoute(
            builder: (context) => const PermissionSetupScreen());
      default:
        developer.log('❌ Unknown route: ${setting.name}', name: 'AppRouter');
        return null;
    }
  }
}
