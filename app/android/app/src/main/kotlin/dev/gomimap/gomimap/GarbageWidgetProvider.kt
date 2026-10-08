// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.widget.RemoteViews
import java.util.concurrent.Executors

class GarbageWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = updateAll(context)
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) = updateAll(context)
    override fun onEnabled(context: Context) = schedule(context)
    override fun onDisabled(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(alarmIntent(context))
    }
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in setOf(REFRESH, PINNED, Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_LOCALE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED)) updateAll(context)
    }

    companion object {
        const val REFRESH = "dev.gomimap.gomimap.WIDGET_REFRESH"
        const val PINNED = "dev.gomimap.gomimap.WIDGET_PINNED"
        const val OPEN = "open_widget_today"
        val executor = Executors.newSingleThreadExecutor()
        fun component(context: Context) = ComponentName(context, GarbageWidgetProvider::class.java)
        fun ids(context: Context) = AppWidgetManager.getInstance(context).getAppWidgetIds(component(context))
        fun openIntent(context: Context) = Intent(context, MainActivity::class.java)
            .putExtra(OPEN, true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        fun pendingOpen(context: Context, mutable: Boolean = false): PendingIntent = PendingIntent.getActivity(
            context, if (mutable) 72 else 71, openIntent(context), PendingIntent.FLAG_UPDATE_CURRENT or
                if (mutable) (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0) else PendingIntent.FLAG_IMMUTABLE)
        fun preview(context: Context): RemoteViews {
            val content = GarbageWidgetData.content(context)
            return RemoteViews(context.packageName, R.layout.garbage_widget_preview).apply {
                setTextViewText(R.id.preview_date, content.dateLabel)
                setTextViewText(R.id.preview_area, content.area)
                setTextViewText(R.id.preview_sample, content.sample)
                setTextViewText(R.id.preview_title, content.title)
            }
        }
        fun views(context: Context, id: Int, content: WidgetContent): RemoteViews {
            val options = AppWidgetManager.getInstance(context).getAppWidgetOptions(id)
            val compact = compact(options)
            val view = RemoteViews(context.packageName, if (compact) R.layout.garbage_widget_compact else R.layout.garbage_widget)
            view.setTextViewText(R.id.widget_date, content.dateLabel)
            if (!compact) {
                view.setTextViewText(R.id.widget_area, content.area)
                view.setTextViewText(R.id.widget_sample, content.sample)
                view.setOnClickPendingIntent(R.id.widget_header, pendingOpen(context))
            } else view.setOnClickPendingIntent(R.id.widget_date, pendingOpen(context))
            val adapter = Intent(context, GarbageWidgetService::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                .putExtra("compact", compact)
            adapter.data = android.net.Uri.parse("gomimap-widget://rows/$id?compact=$compact")
            view.setRemoteAdapter(R.id.widget_rows, adapter)
            view.setEmptyView(R.id.widget_rows, R.id.widget_empty)
            view.setTextViewText(R.id.widget_empty, content.title)
            view.setPendingIntentTemplate(R.id.widget_rows, pendingOpen(context, mutable = true))
            return view
        }
        fun compact(options: Bundle): Boolean =
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) < 220 ||
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) < 220
        @Suppress("DEPRECATION")
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = ids(context)
            if (ids.isEmpty()) return
            val content = GarbageWidgetData.content(context)
            for (id in ids) manager.updateAppWidget(id, views(context, id, content))
            manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_rows)
            schedule(context)
        }
        fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(context, 70,
            Intent(context, GarbageWidgetProvider::class.java).setAction(REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun schedule(context: Context) {
            if (ids(context).isEmpty()) return
            val instant = System.currentTimeMillis()
            val next = GarbageWidgetData.nextRefresh(GarbageWidgetData.read(context), WidgetDate.today(instant),
                GarbageWidgetData.minute(instant), GarbageWidgetData.currentLanguage(context))
            // No exact alarm permission. OS/Doze can delay refresh; the date is explicit.
            context.getSystemService(AlarmManager::class.java)
                .setWindow(AlarmManager.RTC, next, 10 * 60 * 1000L, alarmIntent(context))
        }
    }
}
