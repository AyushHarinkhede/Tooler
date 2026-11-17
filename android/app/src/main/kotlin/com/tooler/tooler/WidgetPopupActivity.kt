package com.tooler.tooler

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

/**
 * Transparent Floating Activity for Home Screen Widget Direct Hover Pages.
 *
 * Launches ONLY the selected Tooler section's Hover Sheet directly on top of
 * the user's phone Home Screen / Wallpaper without opening or flashing the
 * main Tooler app behind it.
 */
class WidgetPopupActivity : MainActivity() {

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun getInitialRoute(): String {
        val toolId = intent?.getStringExtra(ToolerWidgetRenderer.EXTRA_WIDGET_TOOL_ID) ?: "calc"
        return "/widget_popup/$toolId"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        @Suppress("DEPRECATION")
        overridePendingTransition(android.R.anim.fade_in, 0)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val toolId = intent.getStringExtra(ToolerWidgetRenderer.EXTRA_WIDGET_TOOL_ID)
        if (!toolId.isNullOrEmpty()) {
            widgetMethodChannel?.invokeMethod("onPopupToolChange", toolId)
        }
    }
}
