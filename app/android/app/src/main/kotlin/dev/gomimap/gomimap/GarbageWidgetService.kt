// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class GarbageWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(intent.getBooleanExtra("compact", true))
    inner class Factory(private val compact: Boolean) : RemoteViewsFactory {
        private var content = GarbageWidgetData.content(this@GarbageWidgetService)
        private var rows = listOf(content.title)
        override fun onCreate() { onDataSetChanged() }
        override fun onDataSetChanged() {
            content = GarbageWidgetData.content(this@GarbageWidgetService)
            rows = listOf(content.title) + content.lines + if (compact) emptyList() else listOf(content.next).filter { it.isNotEmpty() }
        }
        override fun getCount() = rows.size
        override fun getViewAt(position: Int): RemoteViews {
            if (compact && position == 0) {
                val main = RemoteViews(packageName, R.layout.garbage_widget_compact_main)
                main.setTextViewText(R.id.compact_area, content.area)
                main.setTextViewText(R.id.compact_sample, content.sample)
                main.setTextViewText(R.id.compact_title, content.title)
                main.setOnClickFillInIntent(R.id.compact_body, Intent().putExtra(GarbageWidgetProvider.OPEN, true))
                return main
            }
            val row = RemoteViews(packageName, R.layout.garbage_widget_row)
            row.setTextViewText(R.id.widget_row_text, rows[position])
            row.setTextViewTextSize(R.id.widget_row_text, android.util.TypedValue.COMPLEX_UNIT_SP,
                if (position == 0) 24f else 16f)
            row.setOnClickFillInIntent(R.id.widget_row_text, Intent().putExtra(GarbageWidgetProvider.OPEN, true))
            return row
        }
        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount() = 2
        override fun getItemId(position: Int) = position.toLong()
        override fun hasStableIds() = false
        override fun onDestroy() {}
    }
}
