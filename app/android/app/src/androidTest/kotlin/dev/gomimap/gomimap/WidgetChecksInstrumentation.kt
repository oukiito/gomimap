// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.app.Instrumentation
import android.app.Activity
import android.os.Bundle
import android.os.LocaleList
import android.content.res.Configuration
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import org.json.JSONObject
import java.util.Locale

/** SDK-only native checks; never edits real settings, snapshot or OS clock. */
class WidgetChecksInstrumentation : Instrumentation() {
    private var verifyLive = false
    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        verifyLive = arguments?.getString("verifyLive") == "true"
        start()
    }
    override fun onStart() {
        val result = Bundle()
        try {
            val text = context.assets.open("widget_projection.json").bufferedReader().use { it.readText() }
            val root = GarbageWidgetData.validate(text)
            var checks = 0
            fun verify(ok: Boolean, name: String) { check(ok) { name }; checks++ }
            fun content(date: String, area: String? = "a", tag: String = "ja", minute: Int = 0) = GarbageWidgetData.resolve(
                root, area, tag, WidgetDate.parse(date), GarbageWidgetData.fallback(targetContext, tag), minute)
            verify(content("2026-10-05").status == "collection", "collection status")
            verify(content("2026-10-05").lines.single().contains("08:00"), "deadline")
            verify(content("2026-10-06").date.toString() == "2026-10-07", "no collection today focuses next")
            verify(content("2026-10-08").status == "needsConfirmation", "unknown day")
            verify(content("2026-10-07").next.contains("確認"), "uncertain next day not skipped")
            verify(content("2026-11-09").status == "needsConfirmation", "snapshot expiry")
            verify(content("2026-10-04").status == "needsConfirmation", "before horizon")
            verify(content("2026-10-05", "b").status == "needsConfirmation", "district mismatch")
            verify(content("2026-10-05", null).status == "needsConfirmation", "unconfigured")
            verify(content("2026-10-05", tag="en").title == "Burnable waste", "English")
            verify(GarbageWidgetData.language("zh-Hant", LocaleList(Locale.JAPAN)) == "zh-Hant", "saved language")
            verify(GarbageWidgetData.language(null, LocaleList(Locale.TAIWAN)) == "zh-Hant", "locale fallback")
            verify(WidgetDate.today(1791125999999L).toString() == "2026-10-04", "before Japan midnight")
            verify(WidgetDate.today(1791126000000L).toString() == "2026-10-05", "Japan midnight")
            verify(WidgetDate.parse("2028-02-28").plusDays(1).toString() == "2028-02-29", "leap date")
            verify(WidgetDate.parse("2026-12-31").plusDays(1).toString() == "2027-01-01", "year boundary")
            verify(GarbageWidgetProvider.compact(Bundle().apply {
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 160)
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 160)
            }), "2x2 compact layout")
            verify(!GarbageWidgetProvider.compact(Bundle().apply {
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 300)
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 300)
            }), "expanded layout")
            for (bad in listOf("{}", "[]", text.replace("\"schemaVersion\":2", "\"schemaVersion\":1"))) {
                val rejected = try { GarbageWidgetData.validate(bad); false } catch (_: Exception) { true }
                verify(rejected, "invalid snapshot")
            }
            verify(content("2026-10-05", minute=479).date.toString() == "2026-10-05", "before deadline")
            verify(content("2026-10-05", minute=480).date.toString() == "2026-10-07", "at deadline focuses next")
            verify(content("2026-10-05", minute=600).date.toString() == "2026-10-07", "after deadline")
            verify(content("2026-10-07", minute=600).status == "needsConfirmation", "future uncertainty remains first")
            verify(content("2026-10-08", minute=1200).date.toString() == "2026-10-08", "unknown today does not expire")
            verify(content("2026-10-06").dateLabel.contains("明日"), "tomorrow explicitly labelled")
            verify(GarbageWidgetData.nextRefresh(root, WidgetDate.parse("2026-10-05"), 479, "ja") == WidgetDate.parse("2026-10-05").millis + 480 * 60000L, "alarm at deadline")
            verify(GarbageWidgetData.nextRefresh(root, WidgetDate.parse("2026-10-05"), 480, "ja") == WidgetDate.parse("2026-10-06").millis, "next midnight after deadline")
            val multi = GarbageWidgetData.validate(context.assets.open("widget_multi_projection.json").bufferedReader().use { it.readText() })
            val partial = GarbageWidgetData.resolve(multi, "a", "ja", WidgetDate.parse("2026-10-05"), GarbageWidgetData.fallback(targetContext, "ja"), 480)
            verify(partial.lines.size == 1 && partial.lines.single().contains("09:30"), "only unexpired category")
            verify(partial.date.toString() == "2026-10-05", "partial today date")
            verify(GarbageWidgetData.nextRefresh(multi, WidgetDate.parse("2026-10-05"), 480, "ja") == WidgetDate.parse("2026-10-05").millis + 570 * 60000L, "second deadline alarm")
            val broken = JSONObject(text)
            broken.getJSONObject("locales").getJSONObject("ja").getJSONObject("days").getJSONObject("2026-10-05").getJSONArray("segments").getJSONObject(1).put("minute", 0)
            verify(try { GarbageWidgetData.validate(broken.toString()); false } catch (_: Exception) { true }, "invalid unordered segments rejected")
            verify(GarbageWidgetData.minute(1791154799999L) == 479, "Japan minute before 08")
            verify(GarbageWidgetData.minute(1791154800000L) == 480, "Japan minute at 08")
            runOnMainSync {
                val normal = LayoutInflater.from(targetContext).inflate(R.layout.garbage_widget, null)
                verify(normal.findViewById<View>(R.id.widget_rows) != null, "scrollable content")
                val config = Configuration(targetContext.resources.configuration).apply { fontScale = 2f }
                val large = targetContext.createConfigurationContext(config)
                val row = android.widget.RemoteViews(targetContext.packageName, R.layout.garbage_widget_row)
                row.setTextViewText(R.id.widget_row_text, "収集予定の確認が必要\n複数区分・長い翻訳でも全内容")
                val applied = row.apply(large, null)
                applied.measure(View.MeasureSpec.makeMeasureSpec(320, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
                verify(applied.measuredHeight >= 48, "large text row height")
                verify((applied.findViewById<TextView>(R.id.widget_row_text)).maxLines == Int.MAX_VALUE, "no truncation")
                val compact = android.widget.RemoteViews(targetContext.packageName, R.layout.garbage_widget_compact_main)
                compact.setTextViewText(R.id.compact_area, "豊島区・サンプル地域A")
                compact.setTextViewText(R.id.compact_sample, "開発用サンプル")
                compact.setTextViewText(R.id.compact_title, "収集予定の確認が必要")
                val small = compact.apply(large, null)
                small.measure(View.MeasureSpec.makeMeasureSpec(160, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
                verify(small.measuredHeight > 48, "compact row expands for font scale")
                verify(small.findViewById<TextView>(R.id.compact_title).maxLines == Int.MAX_VALUE, "compact title not truncated")
            }
            if (verifyLive) {
                // Read only our configured app's data. No screen capture,
                // launcher manipulation or clock/settings changes.
                val live = GarbageWidgetData.content(targetContext)
                result.putString("liveDateLabel", live.dateLabel)
                result.putString("liveVersion", live.version ?: "missing")
                val liveRoot = GarbageWidgetData.validate(GarbageWidgetData.file(targetContext).readText(Charsets.UTF_8))
                verify(GarbageWidgetData.read(targetContext) != null, "running app projection validates")
                verify(liveRoot.getString("datasetVersion") == GarbageWidgetData.activeVersion(targetContext), "running dataset version agrees")
                verify(liveRoot.getString("areaId") == GarbageWidgetData.confirmedArea(targetContext), "running district agrees")
                verify(live.version == liveRoot.getString("datasetVersion"), "running widget uses the projection, not fallback")
            }
            result.putString("checks", checks.toString())
            result.putString("result", "PASS")
            finish(Activity.RESULT_OK, result)
        } catch (error: Throwable) {
            result.putString("result", "FAIL")
            result.putString("error", error.toString())
            finish(Activity.RESULT_CANCELED, result)
        }
    }
}
