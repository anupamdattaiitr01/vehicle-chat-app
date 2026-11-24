package com.yourcompany.vehicle_chat_app

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

class MiloApplication : Application() {

    private var flutterPrefs: SharedPreferences? = null

    private val prefListener = SharedPreferences.OnSharedPreferenceChangeListener { prefs, key ->
        if (key == "flutter.pending_native_booking_json" || key == "pending_native_booking_json") {
            val rawJson = prefs.getString(key, null) ?: return@OnSharedPreferenceChangeListener
            if (rawJson.isBlank()) return@OnSharedPreferenceChangeListener

            prefs.edit().remove(key).apply()

            try {
                val jsonObj = JSONObject(rawJson)
                val map = mutableMapOf<String, String>()
                val keys = jsonObj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    map[k] = jsonObj.optString(k, "")
                }
                MiloOverlayManager.handleIncomingBookingPush(this, map)
            } catch (_: Exception) {
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).also {
            it.registerOnSharedPreferenceChangeListener(prefListener)
        }
    }
}