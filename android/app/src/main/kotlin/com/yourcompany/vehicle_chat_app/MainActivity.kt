package com.yourcompany.vehicle_chat_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val overlayChannel = "com.yourcompany.vehicle_chat_app/native_overlay"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, overlayChannel)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(
                    MiloOverlayManager.PREFS_NAME,
                    Context.MODE_PRIVATE
                )
                when (call.method) {
                    "isOverlayPermissionGranted" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        }
                        result.success(granted)
                    }

                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                            !Settings.canDrawOverlays(this)
                        ) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                val fallback = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                                startActivity(fallback)
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    }

                    "syncCredentials" -> {
                        val baseUrl = call.argument<String>("baseUrl")
                        val token = call.argument<String>("token")
                        prefs.edit().apply {
                            if (!baseUrl.isNullOrBlank()) {
                                putString(MiloOverlayManager.KEY_BASE_URL, baseUrl.trim())
                            }
                            if (!token.isNullOrBlank()) {
                                putString(MiloOverlayManager.KEY_AUTH_TOKEN, token.trim())
                            }
                            apply()
                        }
                        result.success(true)
                    }

                    "dismissNativeOverlay" -> {
                        MiloOverlayManager.dismissOverlay(this)
                        result.success(true)
                    }

                    "consumePendingQueryId" -> {
                        val id = prefs.getString(
                            MiloOverlayManager.KEY_PENDING_QUERY_ID,
                            null
                        )
                        if (!id.isNullOrEmpty()) {
                            prefs.edit()
                                .remove(MiloOverlayManager.KEY_PENDING_QUERY_ID)
                                .apply()
                        }
                        result.success(id)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}