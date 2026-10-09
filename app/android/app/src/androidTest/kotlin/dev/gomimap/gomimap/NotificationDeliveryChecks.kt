// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.content.Context
import android.os.Build
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/** Short REAL reservations, only for the QA package on an emulator.
 * Finishes immediately: no test process stays alive to manufacture a delivery.
 * Host observes events with run-as; another instrumentation would restart the app.
 */
object NotificationDeliveryChecks {
    fun run(targetContext: Context, args: Bundle): Bundle {
        val result = Bundle()
        try {
            check(targetContext.packageName == "dev.gomimap.gomimap.qa") { "QA package required" }
            check(Build.HARDWARE in setOf("ranchu", "goldfish")) { "Emulator required" }
            val dir = File(targetContext.filesDir, "qa-delivery").apply { mkdirs() }
            val backup = File(dir, "backup.json")
            val marker = File(dir, "case.json")
            when (args.getString("deliveryAction")) {
                "prepare" -> {
                    check(!backup.exists() && !marker.exists()) { "Clean up the prior case first" }
                    check(!RuntimeClock.frozen(targetContext)) { "Real QA clock required" }
                    check(CollectionNotifications.permission(targetContext) == "allowed") { "Explicit notification permission required" }
                    val label = args.getString("case") ?: "basic"
                    check(label in setOf("basic", "reboot", "doze", "expiry", "cancel"))
                    val delay = (args.getString("delaySeconds") ?: "45").toLong()
                    check(delay in 30..3600)
                    val now = System.currentTimeMillis()
                    val date = WidgetDate.today(now)
                    val due = now + delay * 1000
                    val midnight = date.plusDays(1).millis
                    val expires = if (label == "expiry") due + 1 else minOf(due + 3600000, midnight)
                    check(due < expires && expires < midnight + 1) { "Too close to Japan midnight" }
                    val old = CollectionNotifications.read(targetContext)
                    backup.writeText(JSONObject().put("root", old ?: JSONObject.NULL).toString())
                    File(dir, "events.json").delete()
                    val area = GarbageWidgetData.confirmedArea(targetContext) ?: error("Saved QA district required")
                    val plan = JSONObject().put("schemaVersion", 1).put("municipalityId", "demo-toshima")
                        .put("areaId", area).put("datasetVersion", GarbageWidgetData.activeVersion(targetContext))
                        .put("fixture", true).put("locale", GarbageWidgetData.currentLanguage(targetContext))
                        .put("channelName", old?.getJSONObject("plan")?.optString("channelName", "QA配送試験") ?: "QA配送試験")
                        .put("testTitle", "テスト：{title}")
                        .put("entries", JSONArray().put(JSONObject().put("id", 1).put("due", due).put("expires", expires)
                            .put("date", date.toString()).put("kind", "morning")
                            .put("title", "テスト：予約通知 $label $date")
                            .put("areaLabel", "サンプル地区${area.uppercase()}・配送試験")
                            .put("separator", "・").put("collections", JSONArray().put(JSONObject()
                                .put("name", "配送試験（架空）").put("detail", "ごみ出しには使えません")
                                .put("deadline", midnight)))))
                    marker.writeText(JSONObject().put("case", label).put("preparedAt", now).put("due", due)
                        .put("expires", expires).put("date", date.toString()).toString())
                    check(CollectionNotifications.apply(targetContext, plan.toString())) { "Reservation failed" }
                    check(CollectionNotifications.status(targetContext)["count"] == 1) { "Owned reservation missing" }
                    if (label == "cancel") {
                        check(CollectionNotifications.pause(targetContext))
                        check(CollectionNotifications.status(targetContext)["count"] == 0)
                    }
                    result.putString("case", marker.readText())
                    result.putString("result", "PREPARED")
                }
                "cleanup" -> {
                    check(backup.exists()) { "No test backup" }
                    check(CollectionNotifications.pause(targetContext))
                    val old = JSONObject(backup.readText()).optJSONObject("root")
                    if (old != null) {
                        check(CollectionNotifications.apply(targetContext, old.getJSONObject("plan").toString()))
                        if (old.optBoolean("paused")) check(CollectionNotifications.pause(targetContext))
                    } else File(targetContext.filesDir, "notifications/current.json").delete()
                    backup.delete(); marker.delete()
                    result.putString("result", "RESTORED")
                }
                else -> error("Unknown action")
            }
            return result
        } catch (error: Throwable) {
            result.putString("result", "FAIL")
            result.putString("error", error.toString())
            return result
        }
    }
}
