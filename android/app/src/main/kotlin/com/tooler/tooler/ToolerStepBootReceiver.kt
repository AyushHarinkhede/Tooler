package com.tooler.tooler

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Boot & Package Replaced Receiver for Tooler Hardware Step Sync
 * Schedules JobScheduler hardware sensor hub sync across reboots without
 * launching any 24/7 foreground service.
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
                if (ToolerStepService.hasActivityPermission(context)) {
                    ToolerStepSyncJobService.schedule(context)
                    val pendingResult = goAsync()
                    ToolerStepService.syncHardwareSnapshotOnce(context) {
                        try { pendingResult.finish() } catch (_: Throwable) {}
                    }
                }
            } catch (_: Throwable) {}
        }
    }
}
