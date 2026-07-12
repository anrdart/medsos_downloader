package com.ekalliptus.saver

import android.app.PictureInPictureParams
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

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
                    val title = call.argument<String>("title") ?: "EL-Saver"
                    val subtitle = call.argument<String>("subtitle") ?: "Video Player"

                    result.success(enterPipMode(aspectRatio, title, subtitle))
                }
                "updatePipParams" -> {
                    val aspectRatio = call.argument<Double>("aspectRatio") ?: 16.0 / 9.0
                    val title = call.argument<String>("title") ?: "EL-Saver"
                    val subtitle = call.argument<String>("subtitle") ?: "Video Player"

                    updatePipParams(aspectRatio, title, subtitle)
                    result.success(null)
                }
                "exitPipMode" -> {
                    exitPipMode()
                    result.success(null)
                }
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        try {
                            installApk(apkPath)
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /// Install an APK silently via PackageInstaller.Session.
    /// Requires the user to have granted "Install unknown apps" to this app.
    private fun installApk(apkPath: String) {
        val file = File(apkPath)
        if (!file.exists()) {
            throw IllegalArgumentException("APK file not found: $apkPath")
        }

        val packageInstaller = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL
        )
        val sessionId = packageInstaller.createSession(params)
        val session = packageInstaller.openSession(sessionId)

        try {
            // Add the APK file to the session
            val inputStream = FileInputStream(file)
            val outStream = session.openWrite("el_saver_update.apk", 0, file.length())
            try {
                val buffer = ByteArray(8192)
                var size: Int
                while (inputStream.read(buffer).also { size = it } > 0) {
                    outStream.write(buffer, 0, size)
                }
                session.fsync(outStream)
            } finally {
                outStream.close()
                inputStream.close()
            }

            // Commit the session with a broadcast intent to receive the result
            val intent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                sessionId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            session.commit(pendingIntent.intentSender)
        } catch (e: Exception) {
            session.abandon()
            throw e
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
