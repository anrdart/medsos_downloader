import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:anr_saver/bloc_observer.dart';
import 'package:anr_saver/src/container_injector.dart';
import 'package:anr_saver/src/my_app.dart';
import 'package:anr_saver/src/core/services/update_service.dart';
import 'package:anr_saver/src/core/services/language_service.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    initApp();
    Bloc.observer = MyBlockObserver();

    await LanguageService.instance.initialize();
    await LanguageService.instance.autoDetectLanguage();

    // Firebase init in background
    _initializeFirebase();

    runApp(const MyApp());
  } catch (e) {
    developer.log('Critical error: $e', name: 'Main');
    try {
      initApp();
      Bloc.observer = MyBlockObserver();
    } catch (_) {}
    runApp(const MyApp());
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    developer.log('Firebase initialized', name: 'Main');

    final updateService = UpdateService();
    await updateService.initialize();
    updateService.startPeriodicCheck();
    developer.log('UpdateService started', name: 'Main');
  } catch (e) {
    developer.log('Firebase init failed: $e', name: 'Main');
  }
}
