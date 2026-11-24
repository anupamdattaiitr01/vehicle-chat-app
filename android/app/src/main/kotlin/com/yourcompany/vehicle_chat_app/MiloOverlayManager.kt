package com.yourcompany.vehicle_chat_app

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

object MiloOverlayManager {
    private const val TAG = "MiloNativeOverlay"
    const val PREFS_NAME = "milo_native_dispatch"
    const val KEY_BASE_URL = "base_url"
    const val KEY_AUTH_TOKEN = "auth_token"
    const val KEY_PENDING_QUERY_ID = "pending_query_booking_id"
    private const val CHANNEL_ID = "booking_alerts_channel"

    private var activeOverlayView: View? = null
    private var activeBookingId: String? = null
    private val networkExecutor = Executors.newSingleThreadExecutor()

    fun handleIncomingBookingPush(context: Context, data: Map<String, String>) {
        val appContext = context.applicationContext
        val bookingId = data["_id"] ?: data["bookingId"] ?: data["id"] ?: ""
        Log.i(TAG, "Incoming BOOKING_ASSIGNED push: bookingId=$bookingId")

        if (isAppInForeground(appContext)) {
            Log.i(TAG, "App is in foreground; skipping native overlay.")
            return
        }

        if (bookingId.isNotEmpty() && activeBookingId == bookingId && activeOverlayView != null) {
            Log.i(TAG, "Overlay already active for bookingId=$bookingId; deduplicated.")
            return
        }

        if (bookingId.isNotEmpty() && Settings.canDrawOverlays(appContext)) {
            showNativeFloatingCard(appContext, data, bookingId)
            return
        }

        Log.w(TAG, "Overlay permission unavailable or empty bookingId; showing fallback notification.")
        showFallbackNotification(appContext, data, bookingId)
    }

    fun dismissOverlay(context: Context) {
        val appContext = context.applicationContext
        Handler(Looper.getMainLooper()).post {
            val view = activeOverlayView ?: return@post
            try {
                val wm = appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeViewImmediate(view)
                Log.i(TAG, "Dismissed native overlay view.")
            } catch (e: Exception) {
                Log.w(TAG, "Error removing overlay view: ${e.message}")
            } finally {
                activeOverlayView = null
                activeBookingId = null
            }
        }
    }

    private fun isAppInForeground(context: Context): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        val processes = am.runningAppProcesses ?: return false
        val pkg = context.packageName
        return processes.any {
            it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                    it.processName == pkg
        }
    }

    private fun showNativeFloatingCard(
        context: Context,
        data: Map<String, String>,
        bookingId: String
    ) {
        Handler(Looper.getMainLooper()).post {
            try {
                activeOverlayView?.let { oldView ->
                    try {
                        val wmOld = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                        wmOld.removeViewImmediate(oldView)
                    } catch (_: Exception) {
                    }
                    activeOverlayView = null
                    activeBookingId = null
                }

                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val cardView = buildMiloOfferCard(context, data, bookingId)

                val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    windowType,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                    y = dp(context, 16)
                }

                wm.addView(cardView, params)
                activeOverlayView = cardView
                activeBookingId = bookingId
                Log.i(TAG, "Native WindowManager offer card attached for bookingId=$bookingId")
            } catch (e: Exception) {
                Log.e(TAG, "WindowManager addView failed: ${e.message}", e)
                showFallbackNotification(context, data, bookingId)
            }
        }
    }

    private fun buildMiloOfferCard(
        context: Context,
        data: Map<String, String>,
        bookingId: String
    ): View {
        val passengerName = data["passengerName"] ?: "New Passenger"
        val passengerPhone = data["passengerPhone"] ?: ""
        val pickup = data["pickupLocation"] ?: "Pickup location"
        val drop = data["dropLocation"] ?: "Drop location"
        val scheduledTime = data["scheduledTime"] ?: "Upcoming Ride"
        val notes = data["notes"]?.trim() ?: ""

        val burgundy = Color.parseColor("#7A1C3D")
        val burgundyLight = Color.parseColor("#C23B6B")
        val cardBg = Color.parseColor("#181416")
        val cardBorder = Color.parseColor("#33292E")
        val inputFill = Color.parseColor("#241E21")
        val textPrimary = Color.WHITE
        val textSecondary = Color.parseColor("#B8AEB3")
        val onlineGreen = Color.parseColor("#2ECC71")

        val rootWrapper = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(context, 12), dp(context, 8), dp(context, 12), dp(context, 8))
        }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(context, 20), dp(context, 14), dp(context, 20), dp(context, 20))
            elevation = dp(context, 18).toFloat()
            background = GradientDrawable().apply {
                setColor(cardBg)
                cornerRadius = dp(context, 26).toFloat()
                setStroke(dp(context, 1), cardBorder)
            }
        }

        // Top Drag Handle
        val dragHandle = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(context, 38), dp(context, 4)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(context, 14)
            }
            background = GradientDrawable().apply {
                setColor(cardBorder)
                cornerRadius = dp(context, 999).toFloat()
            }
        }
        card.addView(dragHandle)

        // Top Row: "Milo Fleet" Burgundy Badge + "NEW RIDE" Pill + Close (X)
        val topRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val fleetBadge = TextView(context).apply {
            text = "🚗  Milo Fleet"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTypeface(typeface, Typeface.BOLD)
            setPadding(dp(context, 10), dp(context, 5), dp(context, 10), dp(context, 5))
            background = GradientDrawable().apply {
                setColor(burgundy)
                cornerRadius = dp(context, 8).toFloat()
            }
        }

        val statusPill = TextView(context).apply {
            text = "NEW RIDE"
            setTextColor(Color.parseColor("#FBBF24"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            setTypeface(typeface, Typeface.BOLD)
            letterSpacing = 0.04f
            setPadding(dp(context, 9), dp(context, 5), dp(context, 9), dp(context, 5))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                marginStart = dp(context, 8)
            }
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#3B2D14"))
                cornerRadius = dp(context, 8).toFloat()
            }
        }

        val spacer = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
        }

        val closeBtn = TextView(context).apply {
            text = "✕"
            gravity = Gravity.CENTER
            setTextColor(textPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            layoutParams = LinearLayout.LayoutParams(dp(context, 36), dp(context, 36))
            background = GradientDrawable().apply {
                setColor(inputFill)
                cornerRadius = dp(context, 12).toFloat()
                setStroke(dp(context, 1), cardBorder)
            }
            setOnClickListener { dismissOverlay(context) }
        }

        topRow.addView(fleetBadge)
        topRow.addView(statusPill)
        topRow.addView(spacer)
        topRow.addView(closeBtn)
        card.addView(topRow)

        // Hero Scheduled Time + Bolt Pill
        val timeRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(context, 14), 0, dp(context, 8))
        }

        val timeText = TextView(context).apply {
            text = scheduledTime
            setTextColor(textPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 21f)
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            )
        }

        val boltBadge = TextView(context).apply {
            text = "⚡"
            gravity = Gravity.CENTER
            setTextColor(burgundyLight)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            layoutParams = LinearLayout.LayoutParams(dp(context, 26), dp(context, 26)).apply {
                marginStart = dp(context, 8)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#2E1420"))
            }
        }

        timeRow.addView(timeText)
        timeRow.addView(boltBadge)
        card.addView(timeRow)

        // Passenger Row: Verified Pill + Name & Phone
        val passengerRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val verifiedPill = TextView(context).apply {
            text = "✓ Verified"
            setTextColor(onlineGreen)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
            setTypeface(typeface, Typeface.BOLD)
            setPadding(dp(context, 8), dp(context, 3), dp(context, 8), dp(context, 3))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#143322"))
                cornerRadius = dp(context, 6).toFloat()
            }
        }

        val passengerText = TextView(context).apply {
            text = if (passengerPhone.isNotEmpty()) "$passengerName • $passengerPhone" else passengerName
            setTextColor(textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13.5f)
            setTypeface(typeface, Typeface.BOLD)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            ).apply {
                marginStart = dp(context, 10)
            }
        }

        passengerRow.addView(verifiedPill)
        passengerRow.addView(passengerText)
        card.addView(passengerRow)

        // Divider
        val divider = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(context, 1)
            ).apply {
                topMargin = dp(context, 12)
                bottomMargin = dp(context, 12)
            }
            setBackgroundColor(cardBorder)
        }
        card.addView(divider)

        // Circle-to-Square Route Timeline
        val routeRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
        }

        val timelineCol = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, dp(context, 4), 0, dp(context, 4))
        }

        val pickupDot = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(context, 10), dp(context, 10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(textPrimary)
            }
        }

        val connector = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(context, 2), dp(context, 28)).apply {
                topMargin = dp(context, 4)
                bottomMargin = dp(context, 4)
            }
            setBackgroundColor(cardBorder)
        }

        val dropSquare = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(context, 10), dp(context, 10))
            background = GradientDrawable().apply {
                setColor(burgundyLight)
                cornerRadius = dp(context, 2).toFloat()
            }
        }

        timelineCol.addView(pickupDot)
        timelineCol.addView(connector)
        timelineCol.addView(dropSquare)

        val addressesCol = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            ).apply {
                marginStart = dp(context, 14)
            }
        }

        val pickupLabel = TextView(context).apply {
            text = "PICKUP"
            setTextColor(textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            setTypeface(typeface, Typeface.BOLD)
            letterSpacing = 0.06f
        }

        val pickupValue = TextView(context).apply {
            text = pickup
            setTextColor(textPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
            setTypeface(typeface, Typeface.BOLD)
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
            setPadding(0, dp(context, 2), 0, dp(context, 12))
        }

        val dropLabel = TextView(context).apply {
            text = "DROP-OFF"
            setTextColor(textSecondary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 10.5f)
            setTypeface(typeface, Typeface.BOLD)
            letterSpacing = 0.06f
        }

        val dropValue = TextView(context).apply {
            text = drop
            setTextColor(textPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
            setTypeface(typeface, Typeface.BOLD)
            maxLines = 2
            ellipsize = TextUtils.TruncateAt.END
            setPadding(0, dp(context, 2), 0, 0)
        }

        addressesCol.addView(pickupLabel)
        addressesCol.addView(pickupValue)
        addressesCol.addView(dropLabel)
        addressesCol.addView(dropValue)

        routeRow.addView(timelineCol)
        routeRow.addView(addressesCol)
        card.addView(routeRow)

        // Optional Note Box
        if (notes.isNotEmpty()) {
            val noteBox = TextView(context).apply {
                text = "Note: $notes"
                setTextColor(textSecondary)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
                setPadding(dp(context, 12), dp(context, 9), dp(context, 12), dp(context, 9))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dp(context, 12)
                }
                background = GradientDrawable().apply {
                    setColor(inputFill)
                    cornerRadius = dp(context, 12).toFloat()
                    setStroke(dp(context, 1), cardBorder)
                }
            }
            card.addView(noteBox)
        }

        // Error Banner
        val statusText = TextView(context).apply {
            visibility = View.GONE
            setTextColor(Color.parseColor("#E74C3C"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setTypeface(typeface, Typeface.BOLD)
            setPadding(0, dp(context, 10), 0, 0)
        }
        card.addView(statusText)

        // Action Row: Raise Query (flex 1) + Confirm Ride (flex 2, Burgundy)
        val actionRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(context, 16)
            }
        }

        val queryBtn = Button(context).apply {
            text = "Raise Query"
            isAllCaps = false
            setTextColor(textPrimary)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, dp(context, 48), 1f).apply {
                marginEnd = dp(context, 10)
            }
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                cornerRadius = dp(context, 14).toFloat()
                setStroke(dp(context, 1), cardBorder)
            }
            setOnClickListener {
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit()
                    .putString(KEY_PENDING_QUERY_ID, bookingId)
                    .apply()
                dismissOverlay(context)
                launchAppForBooking(context, data)
            }
        }

        val confirmBtn = Button(context).apply {
            text = "Confirm Ride"
            isAllCaps = false
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(typeface, Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, dp(context, 48), 2f)
            background = GradientDrawable().apply {
                setColor(burgundy)
                cornerRadius = dp(context, 14).toFloat()
            }
        }

        confirmBtn.setOnClickListener {
            confirmBtn.isEnabled = false
            queryBtn.isEnabled = false
            confirmBtn.text = "Confirming..."
            statusText.visibility = View.GONE

            submitAcceptBooking(
                context = context,
                bookingId = bookingId,
                onSuccess = {
                    dismissOverlay(context)
                    cancelBookingNotification(context, bookingId)
                },
                onUnavailable = { message ->
                    statusText.text = message
                    statusText.visibility = View.VISIBLE
                    confirmBtn.text = "Unavailable"
                    Handler(Looper.getMainLooper()).postDelayed({
                        dismissOverlay(context)
                    }, 2200)
                },
                onRetryableError = { message ->
                    statusText.text = message
                    statusText.visibility = View.VISIBLE
                    confirmBtn.isEnabled = true
                    queryBtn.isEnabled = true
                    confirmBtn.text = "Confirm Ride"
                }
            )
        }

        actionRow.addView(queryBtn)
        actionRow.addView(confirmBtn)
        card.addView(actionRow)

        rootWrapper.addView(card)
        return rootWrapper
    }

    private fun submitAcceptBooking(
        context: Context,
        bookingId: String,
        onSuccess: () -> Unit,
        onUnavailable: (String) -> Unit,
        onRetryableError: (String) -> Unit
    ) {
        networkExecutor.execute {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val baseUrl = prefs.getString(KEY_BASE_URL, "")?.trimEnd('/') ?: ""
            val token = prefs.getString(KEY_AUTH_TOKEN, "") ?: ""

            if (baseUrl.isEmpty() || token.isEmpty()) {
                Handler(Looper.getMainLooper()).post {
                    onRetryableError("Session missing — tap Raise Query to open Milo Drive.")
                }
                return@execute
            }

            try {
                val url = URL("$baseUrl/api/bookings/$bookingId/respond")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "PATCH"
                    connectTimeout = 10000
                    readTimeout = 10000
                    doOutput = true
                    setRequestProperty("Authorization", "Bearer $token")
                    setRequestProperty("Content-Type", "application/json")
                }

                val body = JSONObject().put("action", "confirm").toString()
                OutputStreamWriter(conn.outputStream).use { it.write(body) }

                val code = conn.responseCode
                conn.disconnect()

                Handler(Looper.getMainLooper()).post {
                    when (code) {
                        in 200..299 -> onSuccess()
                        400, 404, 409 -> onUnavailable("Booking unavailable (already cancelled or reassigned).")
                        else -> onRetryableError("Server error ($code). Tap Raise Query to open app.")
                    }
                }
            } catch (_: Exception) {
                Handler(Looper.getMainLooper()).post {
                    onRetryableError("Network error. Tap Raise Query to open app.")
                }
            }
        }
    }

    private fun launchAppForBooking(context: Context, data: Map<String, String>) {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            for ((k, v) in data) {
                putExtra(k, v)
            }
        }
        context.startActivity(intent)
    }

    private fun showFallbackNotification(
        context: Context,
        data: Map<String, String>,
        bookingId: String
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Ride Booking Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            for ((k, v) in data) {
                putExtra(k, v)
            }
        }

        val notifId = if (bookingId.isNotEmpty()) bookingId.hashCode() and 0x7fffffff else 1001
        val pendingIntent = PendingIntent.getActivity(
            context,
            notifId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val passengerName = data["passengerName"] ?: "Passenger"
        val pickup = data["pickupLocation"] ?: "Pickup location"
        val scheduledTime = data["scheduledTime"] ?: ""

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("New Ride Assigned • $passengerName")
            .setContentText("$scheduledTime • Pickup: $pickup")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .build()

        manager.notify(notifId, notification)
    }

    private fun cancelBookingNotification(context: Context, bookingId: String) {
        if (bookingId.isEmpty()) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(bookingId.hashCode() and 0x7fffffff)
    }

    private fun dp(context: Context, value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}