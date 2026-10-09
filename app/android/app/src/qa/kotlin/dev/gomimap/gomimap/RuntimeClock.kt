// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/** Compiled only into the separate, non-release QA application. */
object RuntimeClock {
    private const val PACKAGE = "dev.gomimap.gomimap.qa"
    private const val MAX_MILLIS = 4102444799999L // The QA calendar range ends at UTC 2099-12-31.
    private val scenarios = setOf("normal", "tomorrow", "multi")
    private var channel: MethodChannel? = null
    private fun preferences(context: Context) = context.getSharedPreferences("QaClock", Context.MODE_PRIVATE)
    private fun state(context: Context): Map<String, Any> {
        check(context.packageName == PACKAGE)
        try {
            val value = JSONObject(preferences(context).getString("state", "")!!)
            val millis = value.getLong("millis")
            val revision = value.getLong("revision")
            val scenario = value.getString("scenario")
            require(millis in 0..MAX_MILLIS && revision >= 0 && scenario in scenarios)
            val real=value.optBoolean("real",false)
            return mapOf("millis" to if(real)System.currentTimeMillis() else millis, "revision" to revision, "scenario" to scenario, "package" to PACKAGE,"frozen" to !real)
        } catch (_: Exception) {
            return mapOf("millis" to 1791154799000L, "revision" to 0L, "scenario" to "normal", "package" to PACKAGE,"frozen" to true)
        }
    }
    fun now(context: Context): Long = state(context)["millis"] as Long
    fun frozen(context: Context): Boolean = state(context)["frozen"] as Boolean
    fun bundledVersion(context: Context): String = "toshima-clock-qa-${state(context)["scenario"]}-v1"
    fun candidate(context: Context, intent: Intent): Map<String, Any>? {
        if (context.packageName != PACKAGE) return null
        val millis = intent.getStringExtra("gomimap.qa.clock_ms")?.toLongOrNull() ?: return null
        val scenario = intent.getStringExtra("gomimap.qa.scenario") ?: return null
        if (millis !in 0..MAX_MILLIS || scenario !in scenarios) return null
        val real=intent.getStringExtra("gomimap.qa.real")?:"false"
        if(real !in setOf("true","false"))return null
        return mapOf("millis" to millis, "scenario" to scenario,"real" to (real=="true"))
    }
    fun consume(context: Context, intent: Intent): Boolean {
        val value = candidate(context, intent) ?: return false
        val revision = state(context)["revision"] as Long
        if (revision == Long.MAX_VALUE) return false
        val text = JSONObject(value + ("revision" to revision + 1)).toString()
        return preferences(context).edit().putString("state", text).commit()
    }
    fun attach(context: Context, engine: FlutterEngine) {
        check(context.packageName == PACKAGE)
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "dev.gomimap.gomimap/qa_clock").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getState") result.success(state(context)) else result.notImplemented()
            }
        }
    }
    fun notifyChanged(context: Context) { channel?.invokeMethod("changed", state(context)) }

    /** QA-only evidence. No payloads, device IDs, location or network access. */
    @Synchronized fun notificationEvent(context: Context, event: String, id: Int = 0, due: Long = 0) {
        if (context.packageName != PACKAGE) return
        try {
            val file = java.io.File(context.filesDir, "qa-delivery/events.json")
            val events = if (file.exists()) org.json.JSONArray(file.readText()) else org.json.JSONArray()
            val row = JSONObject().put("event", event).put("id", id).put("due", due)
                .put("at", System.currentTimeMillis()).put("elapsed", android.os.SystemClock.elapsedRealtime())
                .put("idle", context.getSystemService(android.os.PowerManager::class.java).isDeviceIdleMode)
                .put("generation", CollectionNotifications.read(context)?.optLong("generation") ?: 0)
            if (event == "posted" || event == "manual") {
                val active = context.getSystemService(android.app.NotificationManager::class.java).activeNotifications
                    .firstOrNull { it.tag == CollectionNotifications.TAG && it.id == id }
                row.put("osPostTime", active?.postTime ?: 0)
            }
            events.put(row)
            val bounded = org.json.JSONArray()
            for (i in maxOf(0, events.length() - 32) until events.length()) bounded.put(events.getJSONObject(i))
            file.parentFile!!.mkdirs()
            val pending = java.io.File(file.parentFile, "events.pending")
            java.io.FileOutputStream(pending).use { it.write(bounded.toString().toByteArray()); it.fd.sync() }
            android.system.Os.rename(pending.path, file.path)
        } catch (_: Exception) { /* Evidence must never change notification delivery. */ }
    }
}
