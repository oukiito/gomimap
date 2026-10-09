// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.content.Context
import android.os.LocaleList
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import android.util.Base64
import java.security.MessageDigest
import java.util.Locale

data class WidgetDay(val date: WidgetDate, val dateLabel: String, val status: String,
    val title: String, val lines: List<String>)
data class WidgetContent(val date: WidgetDate, val dateLabel: String, val area: String,
    val sample: String, val title: String, val lines: List<String>, val next: String,
    val version: String?, val status: String)

object GarbageWidgetData {
    const val MAX_BYTES = 512 * 1024
    fun today(): WidgetDate = WidgetDate.today()
    fun file(context: Context) = File(context.filesDir, "home-widget/current.json")

    fun validate(text: String): JSONObject {
        require(text.toByteArray(Charsets.UTF_8).size <= MAX_BYTES)
        val root = JSONObject(text)
        require(root.getInt("schemaVersion") == 2)
        require(root.getString("municipalityId") == "demo-toshima")
        require(root.getString("areaId") in setOf("a", "b"))
        require(root.getBoolean("fixture")) // This release only displays owned fixtures.
        val version = if (root.isNull("datasetVersion")) null else root.getString("datasetVersion")
        require(version == null || Regex("[A-Za-z0-9][A-Za-z0-9._:-]{0,119}").matches(version))
        require(root.getLong("generatedAt") in 0..253402300799999L)
        val start = WidgetDate.parse(root.getString("start"))
        val end = WidgetDate.parse(root.getString("end"))
        require(end == start.plusDays(35))
        val variants = root.getJSONObject("locales")
        require(variants.length() in 1..10 && variants.has("ja"))
        for (tag in variants.keys()) {
            require(tag in supported)
            val variant = variants.getJSONObject(tag)
            for (key in listOf("areaName", "sample", "uncertain", "chooseArea", "next"))
                require(variant.getString(key).length in 1..1000)
            val days = variant.getJSONObject("days")
            require(days.length() == 35)
            for (i in 0L until 35L) {
                val day = days.getJSONObject(start.plusDays(i).toString())
                validateDisplay(day, version)
                val segments = day.getJSONArray("segments")
                require(segments.length() in 1..33)
                var previous = -1
                for (n in 0 until segments.length()) {
                    val segment = segments.getJSONObject(n)
                    validateDisplay(segment, version)
                    val minute = segment.getInt("minute")
                    require(minute in 0..1439 && minute > previous && (n != 0 || minute == 0))
                    previous = minute
                    val target = WidgetDate.parse(segment.getString("targetDate"))
                    require(target.millis >= start.plusDays(i).millis && target.millis < end.millis)
                    require(segment.getString("next").length <= 4000)
                }
            }
        }
        return root
    }

    private fun validateDisplay(day: JSONObject, version: String?) {
        val status = day.getString("status")
        require(status in setOf("collection", "none", "needsConfirmation"))
        require(day.getString("title").length in 1..4000)
        require(day.getString("dateLabel").length in 1..200)
        val lines = day.getJSONArray("lines")
        require(lines.length() <= 32)
        for (n in 0 until lines.length()) require(lines.getString(n).length in 1..2000)
        require(status == "collection" || lines.length() == 0)
        require(status != "collection" || lines.length() > 0)
        require(version != null || status == "needsConfirmation")
    }

    fun minute(now: Long = System.currentTimeMillis()): Int =
        ((now - WidgetDate.today(now).millis) / 60000).toInt()

    fun nextRefresh(root: JSONObject?, date: WidgetDate, minute: Int, tag: String): Long {
        val segments = root?.optJSONObject("locales")?.optJSONObject(tag)?.optJSONObject("days")
            ?.optJSONObject(date.toString())?.optJSONArray("segments")
        if (segments != null) for (i in 0 until segments.length()) {
            val boundary = segments.getJSONObject(i).getInt("minute")
            if (boundary > minute) return date.millis + boundary * 60000L
        }
        return date.plusDays(1).millis
    }

    fun save(context: Context, text: String) {
        validate(text)
        val current = file(context)
        if (current.isFile && current.length() <= MAX_BYTES && current.readText(Charsets.UTF_8) == text) return
        current.parentFile!!.mkdirs()
        val pending = File(current.parentFile, "pending.json")
        FileOutputStream(pending).use { output ->
            output.write(text.toByteArray(Charsets.UTF_8)); output.fd.sync()
        }
        android.system.Os.rename(pending.path, current.path)
    }

    fun read(context: Context): JSONObject? = try {
        val source = file(context)
        if (source.length() > MAX_BYTES) null else validate(source.readText(Charsets.UTF_8))
    } catch (_: Exception) { null }

    val supported = setOf("ja", "en", "zh-Hans", "zh-Hant", "ko", "vi", "ne", "pt", "es", "fil")
    fun language(preference: String?, locales: LocaleList): String {
        if (preference in supported) return preference!!
        for (i in 0 until locales.size()) {
            val locale = locales[i]
            val code = if (locale.language == "tl") "fil" else locale.language
            if (code == "zh") return if (locale.script == "Hant" ||
                (locale.script.isEmpty() && locale.country in setOf("TW", "HK", "MO"))) "zh-Hant" else "zh-Hans"
            if (code in supported) return code
        }
        return "ja"
    }

    fun confirmedArea(context: Context): String? = try {
        val preferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val text = preferences.getString("flutter.demo.setup.v1", null)
        if (text == null) preferences.getString("flutter.demo.area", null)?.takeIf { it in setOf("a", "b") }
        else JSONObject(text).let { setup ->
            if (setup.getInt("version") == 1 && setup.getString("phase") == "districtSaved")
                setup.getString("area").takeIf { it in setOf("a", "b") } else null
        }
    } catch (_: Exception) { null }

    fun currentLanguage(context: Context): String {
        val preference = try { context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.app.language", null) } catch (_: Exception) { null }
        return language(preference, context.resources.configuration.locales)
    }

    fun fallback(context: Context, tag: String): JSONObject = context.assets.open("widget_labels.json").use {
        JSONObject(it.bufferedReader().readText()).getJSONObject("locales").getJSONObject(tag)
    }

    fun content(context: Context): WidgetContent {
        val instant = RuntimeClock.now(context)
        val tag = currentLanguage(context)
        return resolve(read(context)?.takeIf { it.optString("datasetVersion") == activeVersion(context) },
            confirmedArea(context), tag, WidgetDate.today(instant), fallback(context, tag), minute(instant))
    }

    /** Check the currently stored revision only; scheduling rules remain Dart. */
    fun activeVersion(context: Context): String {
        for (name in listOf("current", "previous")) {
            try {
                val file = File(context.filesDir, "datasets-demo/$name.json")
                if (file.length() > 4 * 1024 * 1024) continue
                val record = JSONObject(file.readText(Charsets.UTF_8))
                require(record.getInt("cacheVersion") == 1)
                val entry = record.getJSONObject("entry")
                require(entry.getString("municipalityId") == "demo-toshima" && entry.getString("kind") == "fixture")
                val bytes = Base64.decode(record.getString("bytes"), Base64.DEFAULT)
                require(bytes.size in 1..(2 * 1024 * 1024) && bytes.size == entry.getInt("sizeBytes"))
                val digest = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
                require(digest == entry.getString("sha256"))
                return entry.getString("version")
            } catch (_: Exception) { /* Try previous complete revision. */ }
        }
        return RuntimeClock.bundledVersion(context) // The pinned, owned fixture for this target.
    }

    fun resolve(root: JSONObject?, areaId: String?, tag: String, date: WidgetDate, labels: JSONObject, minute: Int = 0): WidgetContent {
        val locale = Locale.forLanguageTag(tag)
        val dateLabel = date.format("M/d(E)", locale)
        val area = if (areaId == null) labels.getString("chooseArea")
            else labels.getString("areaName").replace("{area}", areaId.uppercase(Locale.ROOT))
        fun unknown() = WidgetContent(date, dateLabel, area, labels.getString("widgetSample"),
            if (areaId == null) labels.getString("chooseArea") else labels.getString("uncertain"),
            emptyList(), "", null, "needsConfirmation")
        if (root == null || areaId == null || root.getString("areaId") != areaId) return unknown()
        val variant = root.getJSONObject("locales").optJSONObject(tag) ?: return unknown()
        val days = variant.getJSONObject("days")
        val day = days.optJSONObject(date.toString()) ?: return unknown()
        val segments = day.getJSONArray("segments")
        val segment = (0 until segments.length()).map { segments.getJSONObject(it) }
            .lastOrNull { it.getInt("minute") <= minute } ?: return unknown()
        val lines = segment.getJSONArray("lines")
        return WidgetContent(WidgetDate.parse(segment.getString("targetDate")), segment.getString("dateLabel"), variant.getString("areaName"),
            variant.getString("sample"), segment.getString("title"),
            (0 until lines.length()).map { lines.getString(it) }, segment.getString("next"),
            if (root.isNull("datasetVersion")) null else root.getString("datasetVersion"), segment.getString("status"))
    }
}
