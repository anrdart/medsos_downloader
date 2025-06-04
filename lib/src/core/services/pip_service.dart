import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('pip_service');
  static PipService? _instance;
  static PipService get instance => _instance ??= PipService._();

  PipService._();

  final StreamController<bool> _pipModeController =
      StreamController<bool>.broadcast();
  Stream<bool> get pipModeStream => _pipModeController.stream;

  bool _isPipMode = false;
  bool get isPipMode => _isPipMode;

  /// Initialize PIP service
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipModeChanged':
        final bool isInPipMode = call.arguments as bool;
        _updatePipMode(isInPipMode);
        break;
      case 'onUserLeaveHint':
        // Android calls this when user presses home button
        await _tryEnterPipMode();
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Update PIP mode state
  void _updatePipMode(bool isInPipMode) {
    if (_isPipMode != isInPipMode) {
      _isPipMode = isInPipMode;
      _pipModeController.add(_isPipMode);

      if (kDebugMode) {
        print('PIP Mode: $_isPipMode');
      }
    }
  }

  /// Check if device supports PIP mode
  Future<bool> isPipSupported() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool isSupported = await _channel.invokeMethod('isPipSupported');
      return isSupported;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking PIP support: $e');
      }
      return false;
    }
  }

  /// Enter PIP mode
  Future<bool> enterPipMode({
    double? aspectRatio,
    String? title,
    String? subtitle,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final Map<String, dynamic> params = {
        'aspectRatio': aspectRatio ?? 16.0 / 9.0,
        'title': title ?? 'ANR Saver',
        'subtitle': subtitle ?? 'Video Player',
      };

      final bool success = await _channel.invokeMethod('enterPipMode', params);
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error entering PIP mode: $e');
      }
      return false;
    }
  }

  /// Try to enter PIP mode automatically
  Future<void> _tryEnterPipMode() async {
    if (await isPipSupported()) {
      await enterPipMode();
    }
  }

  /// Update PIP mode parameters
  Future<void> updatePipParams({
    double? aspectRatio,
    String? title,
    String? subtitle,
  }) async {
    if (!Platform.isAndroid || !_isPipMode) return;

    try {
      final Map<String, dynamic> params = {
        'aspectRatio': aspectRatio ?? 16.0 / 9.0,
        'title': title ?? 'ANR Saver',
        'subtitle': subtitle ?? 'Video Player',
      };

      await _channel.invokeMethod('updatePipParams', params);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating PIP params: $e');
      }
    }
  }

  /// Exit PIP mode
  Future<void> exitPipMode() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('exitPipMode');
    } catch (e) {
      if (kDebugMode) {
        print('Error exiting PIP mode: $e');
      }
    }
  }

  /// Check if currently in PIP mode by screen dimensions
  bool isPipModeByDimensions(double width, double height) {
    // Typical PIP window dimensions are smaller than 400x400
    const double pipThreshold = 400;
    return width < pipThreshold && height < pipThreshold;
  }

  /// Get optimal PIP aspect ratio based on video dimensions
  double getOptimalAspectRatio(double videoWidth, double videoHeight) {
    if (videoWidth <= 0 || videoHeight <= 0) {
      return 16.0 / 9.0; // Default aspect ratio
    }

    final double ratio = videoWidth / videoHeight;

    // Clamp aspect ratio to reasonable bounds for PIP
    if (ratio > 2.39) return 2.39; // Ultra-wide max
    if (ratio < 0.5) return 0.5; // Portrait min

    return ratio;
  }

  /// Dispose of resources
  void dispose() {
    _pipModeController.close();
  }
}

/// Extension for easier PIP mode detection in widgets
extension PipModeDetection on BuildContext {
  bool get isPipMode {
    final size = MediaQuery.of(this).size;
    return PipService.instance.isPipModeByDimensions(size.width, size.height);
  }
}
