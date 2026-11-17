package com.tooler.tooler

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews

class ToolerFavWidgetProvider : AppWidgetProvider() {

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
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, ToolerFavWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, mgr, id)
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_tooler_1x1)
            val palette = ToolerWidgetRenderer.resolvePalette(context)
            val favToolId = ToolerWidgetRenderer.getFavoriteToolId(context)

            // Ultra-sharp 320x320 supersampled Icon-Only 1x1 Squircle (Zero Text Label)
            val iconBmp = ToolerWidgetRenderer.renderToolButtonBitmap(
                toolId = favToolId,
                sizePx = 320,
                palette = palette,
                isStandalone1x1 = true
            )
            views.setImageViewBitmap(R.id.widget_1x1_icon, iconBmp)

            // Direct Home Screen Floating Hover Overlay Launch
            views.setOnClickPendingIntent(
                R.id.widget_1x1_icon,
                ToolerWidgetRenderer.buildLaunchPendingIntent(context, favToolId, 201)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
