package com.tooler.tooler

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.RemoteViews
import java.util.Locale
import kotlin.math.roundToInt

class ToolerStepWidgetProvider : AppWidgetProvider() {

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

    companion object {
        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, ToolerStepWidgetProvider::class.java)
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
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_tooler_step)
                val palette = ToolerWidgetRenderer.resolvePalette(context)

                // Step telemetry from live service or persisted storage
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val steps = if (ToolerStepService.liveTodaySteps > 0) {
                    ToolerStepService.liveTodaySteps
                } else {
                    prefs.getInt("flutter.tooler_steps_today_count_v2", 0)
                }

                val activeSec = if (ToolerStepService.liveActiveSeconds > 0) {
                    ToolerStepService.liveActiveSeconds
                } else {
                    prefs.getInt("flutter.tooler_steps_active_seconds_v2", 0)
                }

                val distKm = if (ToolerStepService.liveDistanceKm > 0) {
                    ToolerStepService.liveDistanceKm
                } else {
                    (steps * 0.762) / 1000.0
                }

                val speedKmh = if (ToolerStepService.liveSpeedKmh > 0) {
                    ToolerStepService.liveSpeedKmh
                } else if (activeSec > 10 && distKm > 0.01) {
                    (distKm / (activeSec / 3600.0)).coerceIn(1.5, 12.0)
                } else if (steps > 0) {
                    4.5
                } else {
                    0.0
                }

                val calories = (steps * 0.042).roundToInt()

                // Compact, high-efficiency dimensions (well below Android Binder 1MB transaction ceiling)
                val bgW = 320
                val bgH = 190
                val radius = 28f

                // Background Card
                val bgBmp = ToolerWidgetRenderer.renderRoundedCardBackground(bgW, bgH, radius, palette)
                views.setImageViewBitmap(R.id.widget_step_bg, bgBmp)

                // Step Shoe Icon in Header
                val shoeBmp = ToolerWidgetRenderer.renderStepShoeIconBitmap(44, palette)
                views.setImageViewBitmap(R.id.widget_step_icon, shoeBmp)

                // Header Texts & Colors
                views.setTextColor(R.id.widget_step_title, palette.ink)
                views.setTextColor(R.id.widget_step_badge, palette.primary)

                // Main Prominent Steps Count
                val formattedSteps = String.format(Locale.US, "%,d", steps)
                views.setTextViewText(R.id.widget_step_count, formattedSteps)
                views.setTextColor(R.id.widget_step_count, palette.primary)

                // Metric 1: Distance
                val distBmp = ToolerWidgetRenderer.renderDistanceMetricIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_step_dist_icon, distBmp)
                views.setTextViewText(R.id.widget_step_dist_val, String.format(Locale.US, "%.2f km", distKm))
                views.setTextColor(R.id.widget_step_dist_val, palette.ink)
                views.setTextColor(R.id.widget_step_dist_lbl, palette.ink and 0x7FFFFFFF)

                // Metric 2: Avg Speed
                val speedBmp = ToolerWidgetRenderer.renderSpeedMetricIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_step_speed_icon, speedBmp)
                views.setTextViewText(R.id.widget_step_speed_val, String.format(Locale.US, "%.1f km/h", speedKmh))
                views.setTextColor(R.id.widget_step_speed_val, palette.ink)
                views.setTextColor(R.id.widget_step_speed_lbl, palette.ink and 0x7FFFFFFF)

                // Metric 3: Calories
                val calBmp = ToolerWidgetRenderer.renderFlameMetricIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_step_cal_icon, calBmp)
                views.setTextViewText(R.id.widget_step_cal_val, "$calories kcal")
                views.setTextColor(R.id.widget_step_cal_val, palette.ink)
                views.setTextColor(R.id.widget_step_cal_lbl, palette.ink and 0x7FFFFFFF)

                // Tap on Widget opens Step Counter hover sheet
                val launchPi = ToolerWidgetRenderer.buildLaunchPendingIntent(context, "steps", 500)
                views.setOnClickPendingIntent(R.id.widget_step_click_area, launchPi)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                android.util.Log.e("ToolerStepWidget", "Error updating step widget $appWidgetId: ${e.message}", e)
            }
        }
    }
}
