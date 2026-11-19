package com.tooler.tooler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Boot & Package Replaced Receiver for Tooler Step Counter
 * Automatically restarts ToolerStepService when the device reboots
 * ensuring zero step loss across phone restarts with minimal battery usage.
 */
class ToolerStepBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            try {
                val serviceIntent = Intent(context, ToolerStepService::class.java).apply {
                    this.action = ToolerStepService.ACTION_START_TRACKING
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (_: Exception) {}
        }
    }
}
