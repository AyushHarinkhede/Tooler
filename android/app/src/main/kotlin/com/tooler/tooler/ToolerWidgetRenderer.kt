package com.tooler.tooler

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import kotlin.math.cos
import kotlin.math.sin

data class WidgetPalette(
    val cardBg: Int,
    val bubbleBg: Int,
    val primary: Int,
    val ink: Int,
    val border: Int,
    val isDark: Boolean
)

object ToolerWidgetRenderer {
    const val PREFS_NAME = "tooler_widget_prefs"
    const val KEY_COLOR_MODE = "color_mode"       // "app" or "system"
    const val KEY_FAV_TOOL_ID = "fav_tool_id"     // e.g. "calc", "compass", "recorder", etc.
    const val KEY_APP_CARD_BG = "app_card_bg"
    const val KEY_APP_BUBBLE = "app_bubble"
    const val KEY_APP_PRIMARY = "app_primary"
    const val KEY_APP_TEXT = "app_text"
    const val KEY_APP_BORDER = "app_border"
    const val KEY_APP_IS_DARK = "app_is_dark"

    const val KEY_COUNTER_ID = "counter_id"
    const val KEY_COUNTER_NAME = "counter_name"
    const val KEY_COUNTER_VALUE = "counter_value"
    const val KEY_COUNTER_STEP = "counter_step"

    const val EXTRA_WIDGET_TOOL_ID = "widget_tool_id"

    fun getCounterId(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_COUNTER_ID, 0)
    }

    fun getCounterName(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_COUNTER_NAME, "Tally Counter") ?: "Tally Counter"
    }

    fun getCounterValue(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_COUNTER_VALUE, 0)
    }

    fun getCounterStep(context: Context): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_COUNTER_STEP, 1).coerceAtLeast(1)
    }

    fun getSystemPalette(context: Context): WidgetPalette {
        val isNight = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return try {
                if (isNight) {
                    WidgetPalette(
                        cardBg = context.getColor(android.R.color.system_neutral1_900),
                        bubbleBg = context.getColor(android.R.color.system_accent2_800),
                        primary = context.getColor(android.R.color.system_accent1_200),
                        ink = context.getColor(android.R.color.system_neutral1_100),
                        border = context.getColor(android.R.color.system_neutral2_700),
                        isDark = true
                    )
                } else {
                    WidgetPalette(
                        cardBg = context.getColor(android.R.color.system_neutral1_50),
                        bubbleBg = context.getColor(android.R.color.system_accent1_100),
                        primary = context.getColor(android.R.color.system_accent1_600),
                        ink = context.getColor(android.R.color.system_neutral1_900),
                        border = context.getColor(android.R.color.system_neutral2_200),
                        isDark = false
                    )
                }
            } catch (_: Exception) {
                fallbackSystemPalette(isNight)
            }
        }
        return fallbackSystemPalette(isNight)
    }

    private fun fallbackSystemPalette(isNight: Boolean): WidgetPalette {
        return if (isNight) {
            WidgetPalette(
                cardBg = Color.parseColor("#1C1B1F"),
                bubbleBg = Color.parseColor("#2E2C36"),
                primary = Color.parseColor("#D0BCFF"),
                ink = Color.parseColor("#F4EFF4"),
                border = Color.parseColor("#3B3845"),
                isDark = true
            )
        } else {
            WidgetPalette(
                cardBg = Color.parseColor("#FFFBFE"),
                bubbleBg = Color.parseColor("#EDE7F6"),
                primary = Color.parseColor("#6750A4"),
                ink = Color.parseColor("#1C1B1F"),
                border = Color.parseColor("#E3DCE8"),
                isDark = false
            )
        }
    }

    fun resolvePalette(context: Context): WidgetPalette {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorMode = prefs.getString(KEY_COLOR_MODE, "app") ?: "app"
        if (colorMode == "system") {
            return getSystemPalette(context)
        }
        val isDark = prefs.getBoolean(KEY_APP_IS_DARK, false)
        val defaultCard = if (isDark) Color.parseColor("#1B1D24") else Color.parseColor("#FFFFFF")
        val defaultBubble = if (isDark) Color.parseColor("#2A2438") else Color.parseColor("#F3EAFF")
        val defaultPrimary = Color.parseColor("#7C4DFF")
        val defaultText = if (isDark) Color.parseColor("#F5F6FA") else Color.parseColor("#1E2028")
        val defaultBorder = if (isDark) Color.parseColor("#333745") else Color.parseColor("#E7E2F0")

        return WidgetPalette(
            cardBg = prefs.getInt(KEY_APP_CARD_BG, defaultCard),
            bubbleBg = prefs.getInt(KEY_APP_BUBBLE, defaultBubble),
            primary = prefs.getInt(KEY_APP_PRIMARY, defaultPrimary),
            ink = prefs.getInt(KEY_APP_TEXT, defaultText),
            border = prefs.getInt(KEY_APP_BORDER, defaultBorder),
            isDark = isDark
        )
    }

    fun getFavoriteToolId(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_FAV_TOOL_ID, "calc") ?: "calc"
    }

    private fun shiftLuminance(color: Int, factor: Float): Int {
        val a = Color.alpha(color)
        val r = (Color.red(color) * factor).toInt().coerceIn(0, 255)
        val g = (Color.green(color) * factor).toInt().coerceIn(0, 255)
        val b = (Color.blue(color) * factor).toInt().coerceIn(0, 255)
        return Color.argb(a, r, g, b)
    }

    fun buildLaunchPendingIntent(context: Context, toolId: String, requestCode: Int): PendingIntent {
        // "all" switches cleanly into full Tooler Home Screen (MainActivity).
        // Every tool shortcut launches directly into WidgetPopupActivity — a true transparent
        // floating Hover Sheet right over the user's phone Home Screen wallpaper!
        val targetClass = if (toolId == "all") {
            MainActivity::class.java
        } else {
            WidgetPopupActivity::class.java
        }
        val intent = Intent(context, targetClass).apply {
            action = "com.tooler.tooler.OPEN_WIDGET_TOOL_$toolId"
            putExtra(EXTRA_WIDGET_TOOL_ID, toolId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun renderRoundedCardBackground(widthPx: Int, heightPx: Int, radiusPx: Float, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val pad = 6f
        val rect = RectF(pad, pad, widthPx - pad, heightPx - pad)

        // Subtle flagship vertical surface sheen
        val topShade = if (palette.isDark) shiftLuminance(palette.cardBg, 1.12f) else palette.cardBg
        val bottomShade = if (palette.isDark) palette.cardBg else shiftLuminance(palette.cardBg, 0.96f)
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(0f, rect.top, 0f, rect.bottom, topShade, bottomShade, Shader.TileMode.CLAMP)
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)

        // Subtle inner top specular rim for tactile depth
        val innerRect = RectF(pad + 2.5f, pad + 2.5f, widthPx - pad - 2.5f, heightPx - pad - 2.5f)
        val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (palette.isDark) Color.argb(26, 255, 255, 255) else Color.argb(140, 255, 255, 255)
            style = Paint.Style.STROKE
            strokeWidth = 2.5f
        }
        canvas.drawRoundRect(innerRect, (radiusPx - 2.5f).coerceAtLeast(8f), (radiusPx - 2.5f).coerceAtLeast(8f), rimPaint)

        // Crisp outer hairline border
        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.border
            style = Paint.Style.STROKE
            strokeWidth = 3.5f
        }
        canvas.drawRoundRect(rect, radiusPx, radiusPx, borderPaint)
        return bmp
    }

    fun renderToolButtonBitmap(
        toolId: String,
        sizePx: Int,
        palette: WidgetPalette,
        isStandalone1x1: Boolean
    ): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        if (isStandalone1x1) {
            // Supersampled flagship squircle card for 1x1 Home Screen Widget (Pure Icon Only - Zero Text)
            val pad = s * 0.035f
            val cardRect = RectF(pad, pad, s - pad, s - pad)
            val radius = s * 0.27f

            val topShade = if (palette.isDark) shiftLuminance(palette.cardBg, 1.14f) else palette.cardBg
            val bottomShade = if (palette.isDark) palette.cardBg else shiftLuminance(palette.cardBg, 0.96f)
            val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(0f, cardRect.top, 0f, cardRect.bottom, topShade, bottomShade, Shader.TileMode.CLAMP)
                style = Paint.Style.FILL
            }
            canvas.drawRoundRect(cardRect, radius, radius, cardPaint)

            // Subtle inner highlight rim
            val rimRect = RectF(pad + s * 0.012f, pad + s * 0.012f, s - pad - s * 0.012f, s - pad - s * 0.012f)
            val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (palette.isDark) Color.argb(28, 255, 255, 255) else Color.argb(150, 255, 255, 255)
                style = Paint.Style.STROKE
                strokeWidth = s * 0.012f
            }
            canvas.drawRoundRect(rimRect, radius - s * 0.01f, radius - s * 0.01f, rimPaint)

            val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.border
                style = Paint.Style.STROKE
                strokeWidth = s * 0.024f
            }
            canvas.drawRoundRect(cardRect, radius, radius, borderPaint)

            // Soft centered pastel ambient circle behind the icon
            val bubblePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.bubbleBg
                style = Paint.Style.FILL
            }
            canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.35f, bubblePaint)
        } else {
            // Flagship rounded icon tile inside the 4x1 Quick Bar
            val pad = s * 0.06f
            val tileRect = RectF(pad, pad, s - pad, s - pad)
            val tileRadius = s * 0.27f
            val tilePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
                if (toolId == "all") {
                    shader = LinearGradient(
                        0f, tileRect.top, 0f, tileRect.bottom,
                        palette.primary,
                        shiftLuminance(palette.primary, 0.84f),
                        Shader.TileMode.CLAMP
                    )
                } else {
                    color = palette.bubbleBg
                }
            }
            canvas.drawRoundRect(tileRect, tileRadius, tileRadius, tilePaint)

            if (toolId != "all") {
                val tileStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = if (palette.isDark) Color.argb(30, 255, 255, 255) else Color.argb(22, 0, 0, 0)
                    style = Paint.Style.STROKE
                    strokeWidth = s * 0.016f
                }
                canvas.drawRoundRect(tileRect, tileRadius, tileRadius, tileStroke)
            }
        }

        val iconInk = if (!isStandalone1x1 && toolId == "all") Color.WHITE else palette.ink
        val iconAccent = if (!isStandalone1x1 && toolId == "all") Color.WHITE else palette.primary

        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = iconInk
            style = Paint.Style.STROKE
            strokeWidth = s * 0.046f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

        val accentStroke = Paint(strokePaint).apply {
            color = iconAccent
        }

        val accentFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = iconAccent
            style = Paint.Style.FILL
        }

        val inkFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = iconInk
            style = Paint.Style.FILL
        }

        drawToolArtwork(canvas, toolId, s, strokePaint, accentStroke, accentFill, inkFill)
        return bmp
    }

    private fun drawToolArtwork(
        canvas: Canvas,
        toolId: String,
        s: Float,
        stroke: Paint,
        accentStroke: Paint,
        accentFill: Paint,
        inkFill: Paint
    ) {
        when (toolId) {
            "calc" -> {
                // Calculator body
                canvas.drawRoundRect(RectF(s * 0.28f, s * 0.22f, s * 0.72f, s * 0.78f), s * 0.09f, s * 0.09f, stroke)
                // Top LCD screen
                canvas.drawRoundRect(RectF(s * 0.35f, s * 0.30f, s * 0.65f, s * 0.42f), s * 0.035f, s * 0.035f, accentFill)
                // Buttons 2x2
                val r = s * 0.035f
                canvas.drawCircle(s * 0.40f, s * 0.54f, r, inkFill)
                canvas.drawCircle(s * 0.50f, s * 0.54f, r, inkFill)
                canvas.drawCircle(s * 0.60f, s * 0.54f, r, accentFill)
                canvas.drawCircle(s * 0.40f, s * 0.66f, r, inkFill)
                canvas.drawCircle(s * 0.50f, s * 0.66f, r, inkFill)
                canvas.drawCircle(s * 0.60f, s * 0.66f, r, accentFill)
            }
            "calendar" -> {
                // Calendar body
                canvas.drawRoundRect(RectF(s * 0.24f, s * 0.28f, s * 0.76f, s * 0.76f), s * 0.09f, s * 0.09f, stroke)
                // Header divider
                canvas.drawLine(s * 0.25f, s * 0.42f, s * 0.75f, s * 0.42f, stroke)
                // Top binder rings
                canvas.drawLine(s * 0.38f, s * 0.21f, s * 0.38f, s * 0.32f, accentStroke)
                canvas.drawLine(s * 0.62f, s * 0.21f, s * 0.62f, s * 0.32f, accentStroke)
                // Date dots + highlighted today
                val r = s * 0.033f
                canvas.drawCircle(s * 0.37f, s * 0.53f, r, inkFill)
                canvas.drawCircle(s * 0.50f, s * 0.53f, r, inkFill)
                canvas.drawCircle(s * 0.63f, s * 0.53f, r * 1.25f, accentFill)
                canvas.drawCircle(s * 0.37f, s * 0.65f, r, inkFill)
                canvas.drawCircle(s * 0.50f, s * 0.65f, r, inkFill)
            }
            "weather" -> {
                // Minimal sun behind cloud
                canvas.drawLine(s * 0.64f, s * 0.15f, s * 0.64f, s * 0.21f, accentStroke)
                canvas.drawLine(s * 0.77f, s * 0.20f, s * 0.73f, s * 0.25f, accentStroke)
                canvas.drawLine(s * 0.82f, s * 0.35f, s * 0.76f, s * 0.35f, accentStroke)
                canvas.drawCircle(s * 0.62f, s * 0.35f, s * 0.14f, accentFill)
                canvas.drawCircle(s * 0.62f, s * 0.35f, s * 0.14f, stroke)
                val cloud = Path().apply {
                    moveTo(s * 0.26f, s * 0.68f)
                    lineTo(s * 0.74f, s * 0.68f)
                    arcTo(RectF(s * 0.62f, s * 0.44f, s * 0.82f, s * 0.68f), 0f, -90f, false)
                    arcTo(RectF(s * 0.38f, s * 0.32f, s * 0.66f, s * 0.60f), 0f, -140f, false)
                    arcTo(RectF(s * 0.18f, s * 0.46f, s * 0.38f, s * 0.68f), -180f, -90f, false)
                    close()
                }
                canvas.drawPath(cloud, stroke)
                canvas.drawLine(s * 0.34f, s * 0.78f, s * 0.56f, s * 0.78f, accentStroke)
            }
            "games" -> {
                // Modern rounded gamepad
                canvas.drawRoundRect(RectF(s * 0.20f, s * 0.32f, s * 0.80f, s * 0.68f), s * 0.16f, s * 0.16f, stroke)
                // D-pad left
                canvas.drawLine(s * 0.31f, s * 0.50f, s * 0.43f, s * 0.50f, stroke)
                canvas.drawLine(s * 0.37f, s * 0.44f, s * 0.37f, s * 0.56f, stroke)
                // Action buttons right
                canvas.drawCircle(s * 0.62f, s * 0.45f, s * 0.036f, accentFill)
                canvas.drawCircle(s * 0.68f, s * 0.53f, s * 0.036f, accentFill)
                canvas.drawCircle(s * 0.58f, s * 0.55f, s * 0.032f, inkFill)
            }
            "all" -> {
                // 4-tile All Tools bento grid
                val gap = s * 0.06f
                val box = s * 0.19f
                val x1 = s * 0.50f - gap / 2f - box
                val x2 = s * 0.50f + gap / 2f
                val y1 = s * 0.50f - gap / 2f - box
                val y2 = s * 0.50f + gap / 2f
                val cr = s * 0.055f
                canvas.drawRoundRect(RectF(x1, y1, x1 + box, y1 + box), cr, cr, stroke)
                canvas.drawRoundRect(RectF(x2, y1, x2 + box, y1 + box), cr, cr, accentFill)
                canvas.drawRoundRect(RectF(x1, y2, x1 + box, y2 + box), cr, cr, stroke)
                canvas.drawRoundRect(RectF(x2, y2, x2 + box, y2 + box), cr, cr, stroke)
            }
            "compass" -> {
                // Outer compass ring
                canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.28f, stroke)
                // Needle pointing NE
                val pNorth = Path().apply {
                    moveTo(s * 0.62f, s * 0.36f)
                    lineTo(s * 0.46f, s * 0.46f)
                    lineTo(s * 0.54f, s * 0.54f)
                    close()
                }
                canvas.drawPath(pNorth, accentFill)
                val pSouth = Path().apply {
                    moveTo(s * 0.38f, s * 0.64f)
                    lineTo(s * 0.46f, s * 0.46f)
                    lineTo(s * 0.54f, s * 0.54f)
                    close()
                }
                canvas.drawPath(pSouth, stroke)
            }
            "power" -> {
                // Battery shell + terminal
                canvas.drawRoundRect(RectF(s * 0.32f, s * 0.26f, s * 0.68f, s * 0.78f), s * 0.08f, s * 0.08f, stroke)
                canvas.drawRoundRect(RectF(s * 0.43f, s * 0.20f, s * 0.57f, s * 0.26f), s * 0.02f, s * 0.02f, inkFill)
                // Lightning bolt
                val bolt = Path().apply {
                    moveTo(s * 0.52f, s * 0.36f)
                    lineTo(s * 0.41f, s * 0.54f)
                    lineTo(s * 0.50f, s * 0.54f)
                    lineTo(s * 0.48f, s * 0.68f)
                    lineTo(s * 0.59f, s * 0.50f)
                    lineTo(s * 0.50f, s * 0.50f)
                    close()
                }
                canvas.drawPath(bolt, accentFill)
            }
            "recorder" -> {
                // Mic capsule
                canvas.drawRoundRect(RectF(s * 0.40f, s * 0.24f, s * 0.60f, s * 0.55f), s * 0.10f, s * 0.10f, accentFill)
                // Mic U-cradle
                canvas.drawArc(RectF(s * 0.32f, s * 0.35f, s * 0.68f, s * 0.65f), 0f, 180f, false, stroke)
                // Stand
                canvas.drawLine(s * 0.50f, s * 0.65f, s * 0.50f, s * 0.76f, stroke)
                canvas.drawLine(s * 0.38f, s * 0.76f, s * 0.62f, s * 0.76f, stroke)
            }
            "converters" -> {
                // Top right arrow
                canvas.drawLine(s * 0.28f, s * 0.40f, s * 0.72f, s * 0.40f, accentStroke)
                canvas.drawLine(s * 0.62f, s * 0.31f, s * 0.72f, s * 0.40f, accentStroke)
                canvas.drawLine(s * 0.62f, s * 0.49f, s * 0.72f, s * 0.40f, accentStroke)
                // Bottom left arrow
                canvas.drawLine(s * 0.72f, s * 0.60f, s * 0.28f, s * 0.60f, stroke)
                canvas.drawLine(s * 0.38f, s * 0.51f, s * 0.28f, s * 0.60f, stroke)
                canvas.drawLine(s * 0.38f, s * 0.69f, s * 0.28f, s * 0.60f, stroke)
            }
            "alarm" -> {
                canvas.drawCircle(s * 0.50f, s * 0.54f, s * 0.23f, stroke)
                canvas.drawLine(s * 0.50f, s * 0.54f, s * 0.50f, s * 0.41f, accentStroke)
                canvas.drawLine(s * 0.50f, s * 0.54f, s * 0.60f, s * 0.54f, accentStroke)
                // Twin bells
                canvas.drawLine(s * 0.27f, s * 0.35f, s * 0.37f, s * 0.25f, stroke)
                canvas.drawLine(s * 0.73f, s * 0.35f, s * 0.63f, s * 0.25f, stroke)
            }
            "stopwatch" -> {
                canvas.drawCircle(s * 0.50f, s * 0.55f, s * 0.23f, stroke)
                canvas.drawLine(s * 0.42f, s * 0.24f, s * 0.58f, s * 0.24f, accentStroke)
                canvas.drawLine(s * 0.50f, s * 0.24f, s * 0.50f, s * 0.32f, accentStroke)
                canvas.drawLine(s * 0.50f, s * 0.55f, s * 0.60f, s * 0.44f, accentStroke)
            }
            "timer" -> {
                // Hourglass
                canvas.drawLine(s * 0.32f, s * 0.24f, s * 0.68f, s * 0.24f, stroke)
                canvas.drawLine(s * 0.32f, s * 0.76f, s * 0.68f, s * 0.76f, stroke)
                val hg = Path().apply {
                    moveTo(s * 0.35f, s * 0.25f)
                    lineTo(s * 0.65f, s * 0.25f)
                    lineTo(s * 0.50f, s * 0.50f)
                    lineTo(s * 0.65f, s * 0.75f)
                    lineTo(s * 0.35f, s * 0.75f)
                    lineTo(s * 0.50f, s * 0.50f)
                    close()
                }
                canvas.drawPath(hg, stroke)
                canvas.drawCircle(s * 0.50f, s * 0.66f, s * 0.045f, accentFill)
            }
            "security" -> {
                val shield = Path().apply {
                    moveTo(s * 0.50f, s * 0.22f)
                    lineTo(s * 0.74f, s * 0.32f)
                    lineTo(s * 0.72f, s * 0.54f)
                    quadTo(s * 0.66f, s * 0.71f, s * 0.50f, s * 0.78f)
                    quadTo(s * 0.34f, s * 0.71f, s * 0.28f, s * 0.54f)
                    lineTo(s * 0.26f, s * 0.32f)
                    close()
                }
                canvas.drawPath(shield, stroke)
                canvas.drawLine(s * 0.40f, s * 0.50f, s * 0.47f, s * 0.58f, accentStroke)
                canvas.drawLine(s * 0.47f, s * 0.58f, s * 0.61f, s * 0.42f, accentStroke)
            }
            "sizer" -> {
                // Ruler bar
                canvas.drawRoundRect(RectF(s * 0.22f, s * 0.38f, s * 0.78f, s * 0.62f), s * 0.06f, s * 0.06f, stroke)
                canvas.drawLine(s * 0.34f, s * 0.39f, s * 0.34f, s * 0.50f, accentStroke)
                canvas.drawLine(s * 0.45f, s * 0.39f, s * 0.45f, s * 0.47f, stroke)
                canvas.drawLine(s * 0.55f, s * 0.39f, s * 0.55f, s * 0.50f, accentStroke)
                canvas.drawLine(s * 0.66f, s * 0.39f, s * 0.66f, s * 0.47f, stroke)
            }
            "counters" -> {
                canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.27f, stroke)
                canvas.drawLine(s * 0.38f, s * 0.50f, s * 0.62f, s * 0.50f, accentStroke)
                canvas.drawLine(s * 0.50f, s * 0.38f, s * 0.50f, s * 0.62f, accentStroke)
            }
            "tasks" -> {
                canvas.drawRoundRect(RectF(s * 0.28f, s * 0.23f, s * 0.72f, s * 0.77f), s * 0.08f, s * 0.08f, stroke)
                canvas.drawLine(s * 0.37f, s * 0.40f, s * 0.42f, s * 0.45f, accentStroke)
                canvas.drawLine(s * 0.42f, s * 0.45f, s * 0.48f, s * 0.37f, accentStroke)
                canvas.drawLine(s * 0.54f, s * 0.41f, s * 0.64f, s * 0.41f, stroke)
                canvas.drawLine(s * 0.38f, s * 0.58f, s * 0.64f, s * 0.58f, stroke)
            }
            "currency" -> {
                canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.27f, stroke)
                canvas.drawLine(s * 0.41f, s * 0.39f, s * 0.60f, s * 0.39f, accentStroke)
                canvas.drawLine(s * 0.41f, s * 0.48f, s * 0.58f, s * 0.48f, accentStroke)
                canvas.drawLine(s * 0.49f, s * 0.39f, s * 0.49f, s * 0.63f, accentStroke)
            }
            "password" -> {
                canvas.drawRoundRect(RectF(s * 0.29f, s * 0.45f, s * 0.71f, s * 0.76f), s * 0.08f, s * 0.08f, stroke)
                canvas.drawArc(RectF(s * 0.36f, s * 0.24f, s * 0.64f, s * 0.56f), 180f, 180f, false, stroke)
                canvas.drawCircle(s * 0.50f, s * 0.59f, s * 0.048f, accentFill)
            }
            "browser" -> {
                canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.27f, stroke)
                canvas.drawOval(RectF(s * 0.38f, s * 0.23f, s * 0.62f, s * 0.77f), accentStroke)
                canvas.drawLine(s * 0.24f, s * 0.50f, s * 0.76f, s * 0.50f, stroke)
            }
            "radio" -> {
                // Telescopic antenna + retro radio body + speaker grille + tuning dial
                canvas.drawLine(s * 0.34f, s * 0.39f, s * 0.68f, s * 0.22f, stroke)
                canvas.drawCircle(s * 0.68f, s * 0.22f, s * 0.038f, accentFill)
                canvas.drawRoundRect(RectF(s * 0.22f, s * 0.39f, s * 0.78f, s * 0.76f), s * 0.08f, s * 0.08f, stroke)
                canvas.drawCircle(s * 0.39f, s * 0.58f, s * 0.105f, stroke)
                canvas.drawCircle(s * 0.39f, s * 0.58f, s * 0.032f, accentFill)
                canvas.drawLine(s * 0.56f, s * 0.50f, s * 0.71f, s * 0.50f, accentStroke)
                canvas.drawCircle(s * 0.64f, s * 0.64f, s * 0.048f, accentFill)
            }
            "age" -> {
                // Birthday cake + candle flame
                canvas.drawRoundRect(RectF(s * 0.26f, s * 0.48f, s * 0.74f, s * 0.75f), s * 0.07f, s * 0.07f, stroke)
                canvas.drawLine(s * 0.50f, s * 0.36f, s * 0.50f, s * 0.48f, stroke)
                canvas.drawCircle(s * 0.50f, s * 0.30f, s * 0.052f, accentFill)
            }
            "illustrations" -> {
                // Spark star / studio badge
                val star = Path()
                for (i in 0 until 8) {
                    val angle = (i * 45.0) * Math.PI / 180.0
                    val rad = if (i % 2 == 0) s * 0.28f else s * 0.11f
                    val px = s * 0.50f + (rad * cos(angle)).toFloat()
                    val py = s * 0.50f + (rad * sin(angle)).toFloat()
                    if (i == 0) star.moveTo(px, py) else star.lineTo(px, py)
                }
                star.close()
                canvas.drawPath(star, accentFill)
            }
            else -> {
                canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.24f, accentFill)
            }
        }
    }

    fun renderCounterButtonBitmap(isPlus: Boolean, widthPx: Int, heightPx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val pad = 4f
        val rect = RectF(pad, pad, widthPx - pad, heightPx - pad)
        val radius = heightPx * 0.30f

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isPlus) palette.primary else palette.bubbleBg
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(rect, radius, radius, fillPaint)

        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isPlus) shiftLuminance(palette.primary, 1.15f) else palette.border
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }
        canvas.drawRoundRect(rect, radius, radius, borderPaint)

        val symPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isPlus) Color.WHITE else palette.primary
            style = Paint.Style.STROKE
            strokeWidth = (heightPx * 0.12f).coerceAtLeast(6f)
            strokeCap = Paint.Cap.ROUND
        }

        val cx = widthPx / 2f
        val cy = heightPx / 2f
        val arm = heightPx * 0.22f

        canvas.drawLine(cx - arm, cy, cx + arm, cy, symPaint)
        if (isPlus) {
            canvas.drawLine(cx, cy - arm, cx, cy + arm, symPaint)
        }
        return bmp
    }

    fun renderSmallCounterIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.10f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.bubbleBg
            style = Paint.Style.FILL
        }

        val rect = RectF(s * 0.10f, s * 0.10f, s * 0.90f, s * 0.90f)
        canvas.drawRoundRect(rect, s * 0.24f, s * 0.24f, fill)
        canvas.drawRoundRect(rect, s * 0.24f, s * 0.24f, stroke)

        val tickStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.09f
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawLine(s * 0.36f, s * 0.32f, s * 0.36f, s * 0.68f, tickStroke)
        canvas.drawLine(s * 0.50f, s * 0.32f, s * 0.50f, s * 0.68f, tickStroke)
        canvas.drawLine(s * 0.64f, s * 0.32f, s * 0.64f, s * 0.68f, tickStroke)

        return bmp
    }

    fun renderStepShoeIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.09f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.bubbleBg
            style = Paint.Style.FILL
        }

        // Background squircle bubble
        canvas.drawRoundRect(RectF(s * 0.08f, s * 0.08f, s * 0.92f, s * 0.92f), s * 0.26f, s * 0.26f, fill)

        // Shoe outline: sole and upper
        val shoePath = Path().apply {
            moveTo(s * 0.24f, s * 0.68f)
            lineTo(s * 0.78f, s * 0.68f)
            quadTo(s * 0.84f, s * 0.68f, s * 0.80f, s * 0.56f)
            lineTo(s * 0.62f, s * 0.44f)
            lineTo(s * 0.48f, s * 0.32f)
            lineTo(s * 0.34f, s * 0.38f)
            lineTo(s * 0.24f, s * 0.56f)
            close()
        }
        canvas.drawPath(shoePath, stroke)

        // Speed motion trail dots
        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.FILL
        }
        canvas.drawCircle(s * 0.16f, s * 0.48f, s * 0.04f, dotPaint)
        canvas.drawCircle(s * 0.14f, s * 0.64f, s * 0.035f, dotPaint)

        return bmp
    }

    fun renderDistanceMetricIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.11f
            strokeCap = Paint.Cap.ROUND
        }

        // Map pin / waypoint arrow
        val path = Path().apply {
            moveTo(s * 0.20f, s * 0.80f)
            lineTo(s * 0.82f, s * 0.50f)
            lineTo(s * 0.52f, s * 0.42f)
            lineTo(s * 0.44f, s * 0.18f)
            close()
        }
        canvas.drawPath(path, stroke)
        return bmp
    }

    fun renderSpeedMetricIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.10f
            strokeCap = Paint.Cap.ROUND
        }

        // Speedometer arc
        canvas.drawArc(RectF(s * 0.15f, s * 0.15f, s * 0.85f, s * 0.85f), 150f, 240f, false, stroke)

        // Needle pointing up-right
        canvas.drawLine(s * 0.50f, s * 0.50f, s * 0.70f, s * 0.35f, stroke)
        canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.07f, stroke)

        return bmp
    }

    fun renderFlameMetricIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#F97316") // Vivid calorie flame orange
            style = Paint.Style.FILL
        }

        // Flame silhouette
        val flame = Path().apply {
            moveTo(s * 0.50f, s * 0.14f)
            quadTo(s * 0.68f, s * 0.36f, s * 0.68f, s * 0.54f)
            quadTo(s * 0.68f, s * 0.82f, s * 0.50f, s * 0.84f)
            quadTo(s * 0.32f, s * 0.82f, s * 0.32f, s * 0.54f)
            quadTo(s * 0.32f, s * 0.38f, s * 0.50f, s * 0.14f)
            close()
        }
        canvas.drawPath(flame, fill)

        return bmp
    }

    fun renderTasksIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.08f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.bubbleBg
            style = Paint.Style.FILL
        }

        // Background squircle bubble
        canvas.drawRoundRect(RectF(s * 0.08f, s * 0.08f, s * 0.92f, s * 0.92f), s * 0.26f, s * 0.26f, fill)

        // Clipboard / notepad outline
        val pad = RectF(s * 0.24f, s * 0.22f, s * 0.76f, s * 0.82f)
        canvas.drawRoundRect(pad, s * 0.08f, s * 0.08f, stroke)

        // Checklist lines
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.07f
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawLine(s * 0.42f, s * 0.40f, s * 0.68f, s * 0.40f, linePaint)
        canvas.drawLine(s * 0.42f, s * 0.55f, s * 0.68f, s * 0.55f, linePaint)
        canvas.drawLine(s * 0.42f, s * 0.70f, s * 0.68f, s * 0.70f, linePaint)

        // Checkmarks
        val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.065f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val chk1 = Path().apply {
            moveTo(s * 0.30f, s * 0.40f)
            lineTo(s * 0.34f, s * 0.43f)
            lineTo(s * 0.38f, s * 0.37f)
        }
        canvas.drawPath(chk1, checkPaint)

        val chk2 = Path().apply {
            moveTo(s * 0.30f, s * 0.55f)
            lineTo(s * 0.34f, s * 0.58f)
            lineTo(s * 0.38f, s * 0.52f)
        }
        canvas.drawPath(chk2, checkPaint)

        return bmp
    }

    fun renderAddTaskIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.bubbleBg
            style = Paint.Style.FILL
        }
        canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.46f, bgPaint)

        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.06f
        }
        canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.46f, borderPaint)

        val plusPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.11f
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawLine(s * 0.28f, s * 0.50f, s * 0.72f, s * 0.50f, plusPaint)
        canvas.drawLine(s * 0.50f, s * 0.28f, s * 0.50f, s * 0.72f, plusPaint)

        return bmp
    }

    fun renderTaskCheckmarkBitmap(sizePx: Int, completed: Boolean, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        if (completed) {
            val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.primary
                style = Paint.Style.FILL
            }
            canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.42f, fillPaint)

            val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (palette.isDark) Color.BLACK else Color.WHITE
                style = Paint.Style.STROKE
                strokeWidth = s * 0.12f
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            val checkPath = Path().apply {
                moveTo(s * 0.32f, s * 0.50f)
                lineTo(s * 0.45f, s * 0.64f)
                lineTo(s * 0.70f, s * 0.36f)
            }
            canvas.drawPath(checkPath, checkPaint)
        } else {
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.bubbleBg
                style = Paint.Style.FILL
            }
            canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.40f, bgPaint)

            val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = palette.primary
                style = Paint.Style.STROKE
                strokeWidth = s * 0.10f
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.40f, strokePaint)
        }

        return bmp
    }

    fun renderTaskEmptyIconBitmap(sizePx: Int, palette: WidgetPalette): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = sizePx.toFloat()

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.bubbleBg
            style = Paint.Style.FILL
        }
        canvas.drawCircle(s * 0.50f, s * 0.50f, s * 0.44f, bgPaint)

        val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = palette.primary
            style = Paint.Style.STROKE
            strokeWidth = s * 0.11f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        val checkPath = Path().apply {
            moveTo(s * 0.32f, s * 0.50f)
            lineTo(s * 0.46f, s * 0.65f)
            lineTo(s * 0.72f, s * 0.35f)
        }
        canvas.drawPath(checkPath, checkPaint)

        return bmp
    }
}
