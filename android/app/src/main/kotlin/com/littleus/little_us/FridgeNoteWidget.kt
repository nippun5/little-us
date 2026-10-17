package com.littleus.little_us

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import java.text.DateFormat
import java.util.Date

class FridgeNoteWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        render(context, manager, id)
    }
    companion object {
        const val PREFS = "little_us_fridge"
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, FridgeNoteWidget::class.java))
                .forEach { render(context, manager, it) }
        }
        private fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean("enabled", false)
            val views = RemoteViews(context.packageName, R.layout.fridge_note_widget)
            val stamp = prefs.getLong("updatedAt", 0L)
            val synced = if (stamp > 0) DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.SHORT).format(Date(stamp)) else "Never synced"
            views.setTextViewText(R.id.fridge_brand, if (prefs.getBoolean("demo",false) && enabled) "LITTLE US · DEMO" else "LITTLE US")
            views.setTextViewText(R.id.fridge_author, if (enabled) "A NOTE FROM ${prefs.getString("author", "YOUR PERSON")}" else "YOUR LITTLE FRIDGE")
            views.setTextViewText(R.id.fridge_body, if (enabled) prefs.getString("body", "Your next little note will appear here.") else "Open Little us → Notes to choose a note for this widget.")
            views.setTextViewText(R.id.fridge_updated, if (enabled) "Synced $synced · tap to open" else "Note sharing is off")
            // Explicit immutable Activity intent. No credentials or note body in the intent.
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.fridge_root, pending)
            manager.updateAppWidget(id, views)
        }
    }
}
