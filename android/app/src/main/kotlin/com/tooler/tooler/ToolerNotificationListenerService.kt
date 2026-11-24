package com.tooler.tooler

import android.app.Notification
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.lang.ref.WeakReference

/**
 * TOOLER NOTIFICATION SHIELD LISTENER SERVICE
 * -------------------------------------------
 * Genuine Android NotificationListenerService that audits live device notifications
 * and performs 1-click dismissal of all clearable notifications when granted
 * Notification Access by the user in Android Settings.
 */
class ToolerNotificationListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        liveInstance = WeakReference(this)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (liveInstance?.get() === this) {
            liveInstance = null
        }
    }

    override fun onDestroy() {
        if (liveInstance?.get() === this) {
            liveInstance = null
        }
        super.onDestroy()
    }

    companion object {
        @Volatile
        private var liveInstance: WeakReference<ToolerNotificationListenerService>? = null

        fun isListenerEnabled(context: Context): Boolean {
            return try {
                val cn = ComponentName(context, ToolerNotificationListenerService::class.java)
                val flat = cn.flattenToString()
                val shortFlat = "${context.packageName}/.${cn.shortClassName.trimStart('.')}"
                val enabled = Settings.Secure.getString(
                    context.contentResolver,
                    "enabled_notification_listeners"
                ) ?: ""
                enabled.split(':').any { entry ->
                    val trimmed = entry.trim()
                    trimmed.equals(flat, ignoreCase = true) ||
                        trimmed.equals(shortFlat, ignoreCase = true) ||
                        trimmed.endsWith(cn.className, ignoreCase = true)
                }
            } catch (_: Exception) {
                false
            }
        }

        fun getActiveNotificationList(context: Context): List<Map<String, Any>> {
            val result = ArrayList<Map<String, Any>>()
            val pm = context.packageManager
            val svc = liveInstance?.get()

            val sbns: Array<StatusBarNotification> = try {
                when {
                    svc != null -> svc.activeNotifications ?: emptyArray()
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        nm?.activeNotifications ?: emptyArray()
                    }
                    else -> emptyArray()
                }
            } catch (_: Exception) {
                emptyArray()
            }

            val seenKeys = HashSet<String>()
            for (sbn in sbns) {
                try {
                    val key = sbn.key ?: "${sbn.packageName}:${sbn.id}:${sbn.tag}"
                    if (!seenKeys.add(key)) continue
                    val pkg = sbn.packageName ?: continue
                    val notif = sbn.notification ?: continue
                    val extras = notif.extras
                    val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
                    val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
                    val appName = try {
                        val info = pm.getApplicationInfo(pkg, 0)
                        pm.getApplicationLabel(info).toString()
                    } catch (_: Exception) {
                        pkg
                    }
                    val isOngoingFlag = (notif.flags and Notification.FLAG_ONGOING_EVENT) != 0 ||
                        (notif.flags and Notification.FLAG_NO_CLEAR) != 0
                    val isClearable = sbn.isClearable && !isOngoingFlag

                    // Skip Android core system UI non-clearable static indicators from cleanup list
                    if (pkg == "android" && !isClearable) continue

                    result.add(
                        mapOf(
                            "key" to key,
                            "packageName" to pkg,
                            "appName" to appName,
                            "title" to title.ifEmpty { appName },
                            "text" to text,
                            "postTime" to sbn.postTime,
                            "isClearable" to isClearable
                        )
                    )
                } catch (_: Exception) {
                }
            }
            return result
        }

        fun clearAllClearableNotifications(context: Context): Map<String, Any> {
            val svc = liveInstance?.get()
            var clearedCount = 0
            var ongoingCount = 0

            // Always clear Tooler's own notifications via NotificationManager
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                val ownBefore = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    nm?.activeNotifications?.size ?: 0
                } else 0
                if (svc == null && ownBefore > 0) {
                    nm?.cancelAll()
                    clearedCount += ownBefore
                }
            } catch (_: Exception) {
            }

            if (svc != null) {
                try {
                    val active = svc.activeNotifications ?: emptyArray()
                    for (sbn in active) {
                        val notif = sbn.notification
                        val isLocked = notif != null &&
                            ((notif.flags and Notification.FLAG_ONGOING_EVENT) != 0 ||
                                (notif.flags and Notification.FLAG_NO_CLEAR) != 0)
                        if (sbn.isClearable && !isLocked) {
                            try {
                                svc.cancelNotification(sbn.key)
                                clearedCount++
                            } catch (_: Exception) {
                            }
                        } else {
                            ongoingCount++
                        }
                    }
                    // Also trigger full dismiss sweep for remaining dismissible notifications
                    svc.cancelAllNotifications()
                } catch (_: Exception) {
                }
            }

            return mapOf(
                "clearedCount" to clearedCount,
                "remainingOngoingCount" to ongoingCount,
                "listenerConnected" to (svc != null),
                "listenerEnabled" to isListenerEnabled(context)
            )
        }
    }
}
