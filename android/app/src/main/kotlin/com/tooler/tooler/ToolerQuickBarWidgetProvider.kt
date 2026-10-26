package com.tooler.tooler

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews

class ToolerQuickBarWidgetProvider : AppWidgetProvider() {

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
                ComponentName(context, ToolerQuickBarWidgetProvider::class.java)
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
                val views = RemoteViews(context.packageName, R.layout.widget_tooler_4x1)
                val palette = ToolerWidgetRenderer.resolvePalette(context)

                // Compact, high-efficiency dimensions (well below Android Binder 1MB transaction ceiling)
                val bgW = 380
                val bgH = 100
                val radius = 28f

                val bgBmp = ToolerWidgetRenderer.renderRoundedCardBackground(
                    widthPx = bgW,
                    heightPx = bgH,
                    radiusPx = radius,
                    palette = palette
                )
                views.setImageViewBitmap(R.id.widget_4x1_bg, bgBmp)

                // Crisp, lightweight 72x72 icon tiles: Calculator, Calendar, Weather, All Tools
                val iconSize = 72
                views.setImageViewBitmap(
                    R.id.widget_btn_calc,
                    ToolerWidgetRenderer.renderToolButtonBitmap("calc", iconSize, palette, false)
                )
                views.setImageViewBitmap(
                    R.id.widget_btn_calendar,
                    ToolerWidgetRenderer.renderToolButtonBitmap("calendar", iconSize, palette, false)
                )
                views.setImageViewBitmap(
                    R.id.widget_btn_weather,
                    ToolerWidgetRenderer.renderToolButtonBitmap("weather", iconSize, palette, false)
                )
                views.setImageViewBitmap(
                    R.id.widget_btn_all,
                    ToolerWidgetRenderer.renderToolButtonBitmap("all", iconSize, palette, false)
                )

                // Direct Home Screen Floating Hover Overlay for tools; full app switch for "all"
                views.setOnClickPendingIntent(
                    R.id.widget_btn_calc,
                    ToolerWidgetRenderer.buildLaunchPendingIntent(context, "calc", 101)
                )
                views.setOnClickPendingIntent(
                    R.id.widget_btn_calendar,
                    ToolerWidgetRenderer.buildLaunchPendingIntent(context, "calendar", 102)
                )
                views.setOnClickPendingIntent(
                    R.id.widget_btn_weather,
                    ToolerWidgetRenderer.buildLaunchPendingIntent(context, "weather", 103)
                )
                views.setOnClickPendingIntent(
                    R.id.widget_btn_all,
                    ToolerWidgetRenderer.buildLaunchPendingIntent(context, "all", 104)
                )

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                android.util.Log.e("ToolerQuickBarWidget", "Error updating 4x1 widget $appWidgetId: ${e.message}", e)
            }
        }
    }
}
