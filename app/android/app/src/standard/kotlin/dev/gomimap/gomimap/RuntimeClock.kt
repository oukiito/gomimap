// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine

/** Normal build: no QA channel, persisted override, or launch argument parser. */
object RuntimeClock {
    fun now(context: Context): Long = System.currentTimeMillis()
    fun frozen(context: Context): Boolean = false
    fun bundledVersion(context: Context): String = "toshima-demo-v1"
    fun candidate(context: Context, intent: Intent): Map<String, Any>? = null
    fun consume(context: Context, intent: Intent): Boolean = false
    fun attach(context: Context, engine: FlutterEngine) {}
    fun notifyChanged(context: Context) {}
}
