// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Japanese civil dates on API 24+; no new desugaring/runtime dependency. */
data class WidgetDate(val millis: Long) {
    fun plusDays(days: Long) = WidgetDate(millis + days * 86_400_000L)
    fun format(pattern: String, locale: Locale): String = SimpleDateFormat(pattern, locale).apply {
        timeZone = JAPAN; isLenient = false
    }.format(Date(millis))
    override fun toString() = format("yyyy-MM-dd", Locale.ROOT)
    companion object {
        val JAPAN: TimeZone = TimeZone.getTimeZone("Asia/Tokyo")
        fun today(now: Long = System.currentTimeMillis()): WidgetDate {
            val calendar = Calendar.getInstance(JAPAN).apply {
                timeInMillis = now; set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            }
            return WidgetDate(calendar.timeInMillis)
        }
        fun parse(text: String): WidgetDate {
            require(Regex("[0-9]{4}-[0-9]{2}-[0-9]{2}").matches(text))
            val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply {
                timeZone = JAPAN; isLenient = false
            }
            val date = WidgetDate(formatter.parse(text)!!.time)
            require(date.toString() == text)
            return date
        }
    }
}
