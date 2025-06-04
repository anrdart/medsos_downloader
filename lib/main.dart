import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:anr_saver/bloc_observer.dart';
import 'package:anr_saver/src/container_injector.dart';
import 'package:anr_saver/src/my_app.dart';
import 'package:anr_saver/src/core/services/update_service.dart';
import 'config/supabase_config.dart';
import 'dart:io';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('🚀 Starting app initialization...', name: 'Main');

  try {
    // Initialize dependency injection FIRST
    developer.log('📦 Initializing dependency injection...', name: 'Main');
    initApp();
    developer.log('✅ Dependency injection completed', name: 'Main');

    // Setup Bloc observer
    Bloc.observer = MyBlockObserver();
    developer.log('✅ Bloc observer setup completed', name: 'Main');

    // Initialize Supabase in background (non-blocking)
    developer.log('🌐 Starting Supabase initialization...', name: 'Main');
    _initializeSupabaseInBackground();

    // Run app immediately - don't wait for Supabase
    developer.log('🎯 Launching MyApp...', name: 'Main');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    developer.log('❌ Critical error during app initialization: $e',
        name: 'Main');
    developer.log('StackTrace: $stackTrace', name: 'Main');

    // Initialize minimal dependencies and run app anyway
    try {
      initApp();
      Bloc.observer = MyBlockObserver();
    } catch (_) {}

    runApp(const MyApp());
  }
}

Future<void> _initializeSupabaseInBackground() async {
  try {
    // Check internet connectivity before initializing Supabase
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        developer.log('✅ Internet connection available', name: 'Main');
      }
    } catch (e) {
      developer.log('⚠️ No internet connection, continuing offline',
          name: 'Main');
    }

    // Check if Supabase is enabled and configured
    if (!SupabaseConfig.enableSupabase || !SupabaseConfig.isConfigured) {
      developer.log(
          '⚠️ Supabase not configured or disabled, running in offline mode',
          name: 'Main');

      // Initialize UpdateService in offline mode
      try {
        await UpdateService().initialize();
        developer.log('UpdateService initialized in offline mode',
            name: 'Main');
      } catch (e, stackTrace) {
        developer.log('Failed to initialize UpdateService: $e', name: 'Main');
        developer.log('StackTrace: $stackTrace', name: 'Main');
      }
      return;
    }

    // Initialize Supabase with new configuration
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    developer.log('✅ Supabase initialized successfully', name: 'Main');

    // Test Supabase connection
    try {
      final response = await Supabase.instance.client
          .from('app_updates')
          .select('count')
          .count();
      developer.log(
          'Supabase connection test successful: ${response.count} records',
          name: 'Main');
    } catch (e, stackTrace) {
      developer.log('Supabase connection test failed: $e', name: 'Main');
      developer.log('StackTrace: $stackTrace', name: 'Main');
    }

    // Initialize UpdateService (it will handle missing Supabase gracefully)
    try {
      await UpdateService().initialize();
      developer.log('UpdateService initialized successfully', name: 'Main');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize UpdateService: $e', name: 'Main');
      developer.log('StackTrace: $stackTrace', name: 'Main');
    }
  } catch (e, stackTrace) {
    developer.log('❌ Background Supabase initialization failed: $e',
        name: 'Main');
    developer.log('StackTrace: $stackTrace', name: 'Main');
  }
}
