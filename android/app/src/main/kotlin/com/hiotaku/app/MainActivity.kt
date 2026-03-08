package com.hiotaku.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.content.ContentResolver
import android.net.Uri
import android.os.Bundle
import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hiotaku.app/auto_rotation"
    private val SETTINGS_CHANNEL = "com.hiotaku.app/settings"
    private val PIP_CHANNEL = "com.hiotaku.app/pip"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        if (intent?.action == "FLUTTER_NOTIFICATION_CLICK") {
            // Notification was clicked - app will open
            println("App opened by notification click")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAutoRotationEnabled" -> {
                    val isEnabled = isAutoRotationEnabled()
                    result.success(isEnabled)
                }
                "openAutoRotationSettings" -> {
                    openAutoRotationSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPiP" -> {
                    try {
                        enterPictureInPictureMode()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun enterPictureInPictureMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            super.enterPictureInPictureMode(params)
        }
    }

    private fun isAutoRotationEnabled(): Boolean {
        return try {
            Settings.System.getInt(
                contentResolver,
                Settings.System.ACCELEROMETER_ROTATION,
                0
            ) == 1
        } catch (e: Exception) {
            true // Default to true if we can't check
        }
    }

    private fun openAutoRotationSettings() {
        try {
            // Try to open display settings first
            val intent = Intent(Settings.ACTION_DISPLAY_SETTINGS)
            startActivity(intent)
        } catch (e: Exception) {
            try {
                // Fallback to general settings
                val intent = Intent(Settings.ACTION_SETTINGS)
                startActivity(intent)
            } catch (e: Exception) {
                // Silent error handling
            }
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (e: Exception) {
            try {
                // Fallback to general app settings
                val intent = Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS)
                startActivity(intent)
            } catch (e: Exception) {
                // Silent error handling
            }
        }
    }
}
