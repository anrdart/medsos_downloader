package com.example.anr_saver

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pip_service"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> {
                    result.success(isPipSupported())
                }
                "enterPipMode" -> {
                    val aspectRatio = call.argument<Double>("aspectRatio") ?: 16.0 / 9.0
                    val title = call.argument<String>("title") ?: "ANR Saver"
                    val subtitle = call.argument<String>("subtitle") ?: "Video Player"
                    
                    result.success(enterPipMode(aspectRatio, title, subtitle))
                }
                "updatePipParams" -> {
                    val aspectRatio = call.argument<Double>("aspectRatio") ?: 16.0 / 9.0
                    val title = call.argument<String>("title") ?: "ANR Saver"
                    val subtitle = call.argument<String>("subtitle") ?: "Video Player"
                    
                    updatePipParams(aspectRatio, title, subtitle)
                    result.success(null)
                }
                "exitPipMode" -> {
                    exitPipMode()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isPipSupported(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE)
        } else {
            false
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun enterPipMode(aspectRatio: Double, title: String, subtitle: String): Boolean {
        return try {
            if (!isPipSupported()) return false
            
            val rational = Rational(
                (aspectRatio * 1000).toInt(),
                1000
            )
            
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(rational)
                .build()
            
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updatePipParams(aspectRatio: Double, title: String, subtitle: String) {
        try {
            if (!isPipSupported() || !isInPictureInPictureMode) return
            
            val rational = Rational(
                (aspectRatio * 1000).toInt(),
                1000
            )
            
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(rational)
                .build()
            
            setPictureInPictureParams(params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun exitPipMode() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode) {
                // Move task to front to exit PIP mode
                moveTaskToBack(false)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        
        // Notify Flutter about PIP mode change
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        
        // Notify Flutter that user pressed home button
        methodChannel?.invokeMethod("onUserLeaveHint", null)
    }
} 