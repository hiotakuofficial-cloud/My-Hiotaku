package com.hiotaku.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.content.ContentResolver

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hiotaku.app/auto_rotation"

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
}
