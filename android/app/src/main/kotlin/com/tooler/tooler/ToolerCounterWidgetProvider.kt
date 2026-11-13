package com.tooler.tooler

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONArray

class ToolerCounterWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == ACTION_COUNTER_INC || action == ACTION_COUNTER_DEC) {
            val prefs = context.getSharedPreferences(ToolerWidgetRenderer.PREFS_NAME, Context.MODE_PRIVATE)
            val curVal = prefs.getInt(ToolerWidgetRenderer.KEY_COUNTER_VALUE, 0)
            val step = prefs.getInt(ToolerWidgetRenderer.KEY_COUNTER_STEP, 1).coerceAtLeast(1)
            val counterId = prefs.getInt(ToolerWidgetRenderer.KEY_COUNTER_ID, 0)

            val newVal = if (action == ACTION_COUNTER_INC) {
                curVal + step
            } else {
                (curVal - step).coerceAtLeast(0)
            }

            prefs.edit().putInt(ToolerWidgetRenderer.KEY_COUNTER_VALUE, newVal).apply()

            // Keep Flutter storage seamlessly updated in real time
            syncValueToFlutter(context, counterId, newVal)

            // Trigger milestone notification if 108 chants or centenary milestone is crossed
            if (action == ACTION_COUNTER_INC && (newVal == 108 || (newVal > 0 && newVal % 100 == 0))) {
                triggerMilestoneNotification(context, ToolerWidgetRenderer.getCounterName(context), newVal)
            }

            // Immediately redraw all 2x2 counter widgets
            updateAllWidgets(context)
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_COUNTER_INC = "com.tooler.tooler.ACTION_COUNTER_INC"
        const val ACTION_COUNTER_DEC = "com.tooler.tooler.ACTION_COUNTER_DEC"

        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, ToolerCounterWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, mgr, id)
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_tooler_2x2)
            val palette = ToolerWidgetRenderer.resolvePalette(context)

            val name = ToolerWidgetRenderer.getCounterName(context)
            val value = ToolerWidgetRenderer.getCounterValue(context)

            val opts = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWdp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 140).coerceAtLeast(100)
            val minHdp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140).coerceAtLeast(100)

            val density = 3.5f
            val bgW = (minWdp * density).toInt().coerceIn(400, 900)
            val bgH = (minHdp * density).toInt().coerceIn(400, 900)
            val radius = (bgH * 0.16f).coerceAtMost(80f)

            // Render supersampled background card
            val bgBmp = ToolerWidgetRenderer.renderRoundedCardBackground(bgW, bgH, radius, palette)
            views.setImageViewBitmap(R.id.widget_2x2_bg, bgBmp)

            // Small counter icon in header
            val iconBmp = ToolerWidgetRenderer.renderSmallCounterIconBitmap(80, palette)
            views.setImageViewBitmap(R.id.widget_counter_icon, iconBmp)

            // Counter name & colors
            views.setTextViewText(R.id.widget_counter_name, name)
            views.setTextColor(R.id.widget_counter_name, palette.ink)
            views.setTextColor(R.id.widget_counter_badge, palette.primary)

            // Counter value & color
            views.setTextViewText(R.id.widget_counter_value, value.toString())
            views.setTextColor(R.id.widget_counter_value, palette.primary)

            // Button bitmaps
            val btnW = 200
            val btnH = 80
            val minusBmp = ToolerWidgetRenderer.renderCounterButtonBitmap(false, btnW, btnH, palette)
            val plusBmp = ToolerWidgetRenderer.renderCounterButtonBitmap(true, btnW, btnH, palette)
            views.setImageViewBitmap(R.id.widget_btn_minus, minusBmp)
            views.setImageViewBitmap(R.id.widget_btn_plus, plusBmp)

            // Minus Broadcast intent
            val decIntent = Intent(context, ToolerCounterWidgetProvider::class.java).apply {
                action = ACTION_COUNTER_DEC
            }
            val decPi = PendingIntent.getBroadcast(
                context,
                301,
                decIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_minus, decPi)

            // Plus Broadcast intent
            val incIntent = Intent(context, ToolerCounterWidgetProvider::class.java).apply {
                action = ACTION_COUNTER_INC
            }
            val incPi = PendingIntent.getBroadcast(
                context,
                302,
                incIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_plus, incPi)

            // Open Tally Counter hover sheet on header / number tap
            val launchPi = ToolerWidgetRenderer.buildLaunchPendingIntent(context, "counters", 300)
            views.setOnClickPendingIntent(R.id.widget_counter_header, launchPi)
            views.setOnClickPendingIntent(R.id.widget_counter_value, launchPi)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun syncValueToFlutter(context: Context, counterId: Int, newVal: Int) {
            try {
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = flutterPrefs.getString("flutter.tooler_counters", null)
                if (jsonStr != null && jsonStr.isNotEmpty()) {
                    val array = JSONArray(jsonStr)
                    var matched = false
                    for (i in 0 until array.length()) {
                        val item = array.getJSONObject(i)
                        if (item.optInt("id") == counterId || (counterId == 0 && array.length() == 1)) {
                            item.put("value", newVal)
                            matched = true
                            break
                        }
                    }
                    if (matched) {
                        flutterPrefs.edit()
                            .putString("flutter.tooler_counters", array.toString())
                            .remove("flutter.tooler_counters_checksum")
                            .apply()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("ToolerCounterWidget", "syncValueToFlutter error: ${e.message}")
            }
        }
        private fun triggerMilestoneNotification(context: Context, name: String, value: Int) {
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager ?: return
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    val channel = android.app.NotificationChannel(
                        "tooler_tally_channel",
                        "Tally Counter Milestones",
                        android.app.NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Goal completions and sacred counting milestones"
                        enableVibration(true)
                    }
                    nm.createNotificationChannel(channel)
                }
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)
                val pi = PendingIntent.getActivity(
                    context,
                    5001,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                val is108 = (value == 108)
                val title = if (is108) "📿 Sacred 108 Chants Completed: $name!" else "🎯 Milestone: $name ($value counts)"
                val body = "You just crossed $value counts on $name. Tap to view counter."

                val builder = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    android.app.Notification.Builder(context, "tooler_tally_channel")
                } else {
                    @Suppress("DEPRECATION")
                    android.app.Notification.Builder(context)
                }
                val notif = builder
                    .setSmallIcon(R.drawable.ic_step_notification)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setAutoCancel(true)
                    .setContentIntent(pi)
                    .build()
                nm.notify(5001, notif)
            } catch (_: Throwable) {}
        }
    }
}
