package com.silentrecorder.silent_recorder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            // The flutter_background_service will auto-start if configured
            // This receiver ensures the app process is alive after reboot
        }
    }
}
