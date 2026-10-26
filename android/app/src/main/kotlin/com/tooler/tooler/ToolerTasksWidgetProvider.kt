package com.tooler.tooler

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class ToolerTasksWidgetProvider : AppWidgetProvider() {

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
        if (action == ACTION_TASK_TOGGLE_COMPLETE) {
            val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
            if (taskId != -1) {
                toggleTaskCompletion(context, taskId)
                updateAllWidgets(context)
                return
            }
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_TASK_TOGGLE_COMPLETE = "com.tooler.tooler.ACTION_TASK_TOGGLE_COMPLETE"
        const val EXTRA_TASK_ID = "extra_task_id"

        private data class WidgetTask(
            val id: Int,
            val text: String,
            val completed: Boolean,
            val category: String,
            val priority: String,
            val notes: String
        )

        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, ToolerTasksWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, mgr, id)
            }
        }

        private fun toggleTaskCompletion(context: Context, taskId: Int) {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val rawJson = prefs.getString("flutter.tooler_tasks", null)
                if (!rawJson.isNullOrEmpty()) {
                    val array = JSONArray(rawJson)
                    var changed = false
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        if (obj.optInt("id") == taskId) {
                            val cur = obj.optBoolean("completed", false)
                            obj.put("completed", !cur)
                            changed = true
                            break
                        }
                    }
                    if (changed) {
                        prefs.edit()
                            .putString("flutter.tooler_tasks", array.toString())
                            .remove("flutter.tooler_tasks_checksum")
                            .apply()
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("ToolerTasksWidget", "toggleTaskCompletion error: ${e.message}")
            }
        }

        private fun loadTasksFromPrefs(context: Context): List<WidgetTask> {
            val list = mutableListOf<WidgetTask>()
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val rawJson = prefs.getString("flutter.tooler_tasks", null)
                if (!rawJson.isNullOrEmpty()) {
                    val array = JSONArray(rawJson)
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val id = obj.optInt("id", 0)
                        val text = obj.optString("text", "")
                        val completed = obj.optBoolean("completed", false)
                        val category = obj.optString("category", "Personal")
                        val priority = obj.optString("priority", "Medium")
                        val notes = obj.optString("notes", "")
                        if (text.isNotEmpty() || notes.isNotEmpty()) {
                            list.add(WidgetTask(id, text, completed, category, priority, notes))
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("ToolerTasksWidget", "loadTasks error: ${e.message}")
            }
            return list
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null
        ) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_tooler_tasks)
                val palette = ToolerWidgetRenderer.resolvePalette(context)

                // Compact, high-efficiency dimensions (well below Android Binder 1MB transaction ceiling)
                val bgW = 320
                val bgH = 220
                val radius = 28f

                // Supersampled rounded card background
                val bgBmp = ToolerWidgetRenderer.renderRoundedCardBackground(bgW, bgH, radius, palette)
                views.setImageViewBitmap(R.id.widget_tasks_bg, bgBmp)

                // Header Icon: Tasks / Notebook
                val taskIconBmp = ToolerWidgetRenderer.renderTasksIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_tasks_icon, taskIconBmp)

                // Header Titles & Badge
                views.setTextColor(R.id.widget_tasks_title, palette.ink)
                views.setTextColor(R.id.widget_tasks_badge, palette.primary)

                // Add Task [+] button icon in header
                val addIconBmp = ToolerWidgetRenderer.renderAddTaskIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_btn_add_task_icon, addIconBmp)

                // Empty state icon
                val emptyIconBmp = ToolerWidgetRenderer.renderTaskEmptyIconBitmap(36, palette)
                views.setImageViewBitmap(R.id.widget_tasks_empty_icon, emptyIconBmp)
                views.setTextColor(R.id.widget_tasks_empty_text, palette.ink and 0x8AFFFFFF.toInt())

                // Tasks collection
                val allTasks = loadTasksFromPrefs(context)
                val pendingTasks = allTasks.filter { !it.completed }

                // Header badge
                views.setTextViewText(
                    R.id.widget_tasks_badge,
                    if (pendingTasks.isEmpty()) "ALL DONE" else "${pendingTasks.size} PENDING"
                )

                val opts = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minHdp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110).coerceAtLeast(80)

                // Height-adaptive max visible rows
                val maxRows = when {
                    minHdp < 130 -> 2
                    minHdp < 200 -> 3
                    minHdp < 280 -> 4
                    else -> 5
                }

                // Launch PendingIntent for general Task hover sheet
                val listIntent = Intent(context, WidgetPopupActivity::class.java).apply {
                    putExtra(ToolerWidgetRenderer.EXTRA_WIDGET_TOOL_ID, "tasks")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val listPi = PendingIntent.getActivity(
                    context,
                    600,
                    listIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_tasks_header, listPi)
                views.setOnClickPendingIntent(R.id.widget_tasks_more, listPi)

                // Launch PendingIntent for Add Task (opens composer directly)
                val addIntent = Intent(context, WidgetPopupActivity::class.java).apply {
                    putExtra(ToolerWidgetRenderer.EXTRA_WIDGET_TOOL_ID, "tasks_add")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val addPi = PendingIntent.getActivity(
                    context,
                    601,
                    addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_btn_add_task, addPi)
                views.setOnClickPendingIntent(R.id.widget_tasks_empty, addPi)

                // Row definitions
                val rowIds = intArrayOf(
                    R.id.widget_task_row_1,
                    R.id.widget_task_row_2,
                    R.id.widget_task_row_3,
                    R.id.widget_task_row_4,
                    R.id.widget_task_row_5
                )
                val checkIds = intArrayOf(
                    R.id.widget_task_check_1,
                    R.id.widget_task_check_2,
                    R.id.widget_task_check_3,
                    R.id.widget_task_check_4,
                    R.id.widget_task_check_5
                )
                val titleIds = intArrayOf(
                    R.id.widget_task_title_1,
                    R.id.widget_task_title_2,
                    R.id.widget_task_title_3,
                    R.id.widget_task_title_4,
                    R.id.widget_task_title_5
                )
                val subIds = intArrayOf(
                    R.id.widget_task_sub_1,
                    R.id.widget_task_sub_2,
                    R.id.widget_task_sub_3,
                    R.id.widget_task_sub_4,
                    R.id.widget_task_sub_5
                )

                val checkBmp = ToolerWidgetRenderer.renderTaskCheckmarkBitmap(32, false, palette)

                if (pendingTasks.isEmpty()) {
                    views.setViewVisibility(R.id.widget_tasks_empty, View.VISIBLE)
                    for (rId in rowIds) {
                        views.setViewVisibility(rId, View.GONE)
                    }
                    views.setViewVisibility(R.id.widget_tasks_more, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_tasks_empty, View.GONE)
                    val visibleCount = pendingTasks.size.coerceAtMost(maxRows)
                    for (i in rowIds.indices) {
                        if (i < visibleCount) {
                            val task = pendingTasks[i]
                            views.setViewVisibility(rowIds[i], View.VISIBLE)
                            views.setImageViewBitmap(checkIds[i], checkBmp)
                            views.setTextViewText(titleIds[i], task.text.ifEmpty { task.notes.take(30) })
                            views.setTextColor(titleIds[i], palette.ink)

                            // Subtitle info
                            val subText = if (task.notes.isNotEmpty() && task.text.isNotEmpty()) {
                                task.notes.take(35)
                            } else {
                                "${task.category} • ${task.priority}"
                            }
                            views.setTextViewText(subIds[i], subText)
                            views.setTextColor(subIds[i], palette.ink and 0x8AFFFFFF.toInt())

                            // Row text click -> open hover sheet
                            views.setOnClickPendingIntent(titleIds[i], listPi)
                            views.setOnClickPendingIntent(subIds[i], listPi)

                            // Checkbox click -> mark completed & remove from widget pending
                            val checkIntent = Intent(context, ToolerTasksWidgetProvider::class.java).apply {
                                action = ACTION_TASK_TOGGLE_COMPLETE
                                putExtra(EXTRA_TASK_ID, task.id)
                            }
                            val checkPi = PendingIntent.getBroadcast(
                                context,
                                700 + i,
                                checkIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            views.setOnClickPendingIntent(checkIds[i], checkPi)
                        } else {
                            views.setViewVisibility(rowIds[i], View.GONE)
                        }
                    }

                    // Show more tasks footer if pending > maxRows
                    if (pendingTasks.size > maxRows) {
                        views.setViewVisibility(R.id.widget_tasks_more, View.VISIBLE)
                        views.setTextViewText(R.id.widget_tasks_more, "+ ${pendingTasks.size - maxRows} more tasks in app")
                        views.setTextColor(R.id.widget_tasks_more, palette.primary)
                    } else {
                        views.setViewVisibility(R.id.widget_tasks_more, View.GONE)
                    }
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                android.util.Log.e("ToolerTasksWidget", "Error updating tasks widget $appWidgetId: ${e.message}", e)
            }
        }
    }
}
