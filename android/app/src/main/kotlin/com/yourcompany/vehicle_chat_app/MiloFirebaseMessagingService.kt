package com.yourcompany.vehicle_chat_app

import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

class MiloFirebaseMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        if (data["type"] == "BOOKING_ASSIGNED") {
            MiloOverlayManager.handleIncomingBookingPush(this, data)
            return
        }
        super.onMessageReceived(remoteMessage)
    }
}