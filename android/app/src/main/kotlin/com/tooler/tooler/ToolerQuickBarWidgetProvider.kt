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
            val views = RemoteViews(context.packageName, R.layout.widget_tooler_4x1)
            val palette = ToolerWidgetRenderer.resolvePalette(context)

            val opts = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWdp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 280).coerceAtLeast(180)
            val minHdp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 64).coerceAtLeast(48)

            // Supersampled crisp proportional background matching launcher cell aspect ratio
            val density = 3.5f
            val bgW = (minWdp * density).toInt().coerceIn(720, 1400)
            val bgH = (minHdp * density).toInt().coerceIn(200, 440)
            val radius = (bgH * 0.34f).coerceAtMost(92f)

            val bgBmp = ToolerWidgetRenderer.renderRoundedCardBackground(
                widthPx = bgW,
                heightPx = bgH,
                radiusPx = radius,
                palette = palette
            )
            views.setImageViewBitmap(R.id.widget_4x1_bg, bgBmp)

            // Ultra-sharp 260x260 supersampled icon tiles: Calculator, Calendar, Games, All Tools
            val iconSize = 260
            views.setImageViewBitmap(
                R.id.widget_btn_calc,
                ToolerWidgetRenderer.renderToolButtonBitmap("calc", iconSize, palette, false)
            )
            views.setImageViewBitmap(
                R.id.widget_btn_calendar,
                ToolerWidgetRenderer.renderToolButtonBitmap("calendar", iconSize, palette, false)
            )
            views.setImageViewBitmap(
                R.id.widget_btn_games,
                ToolerWidgetRenderer.renderToolButtonBitmap("games", iconSize, palette, false)
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
                R.id.widget_btn_games,
                ToolerWidgetRenderer.buildLaunchPendingIntent(context, "games", 103)
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_all,
                ToolerWidgetRenderer.buildLaunchPendingIntent(context, "all", 104)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
