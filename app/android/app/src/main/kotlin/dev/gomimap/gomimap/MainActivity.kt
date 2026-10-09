// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Build
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var notifications: NotificationBridge? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        RuntimeClock.consume(this, intent)
        super.onCreate(savedInstanceState)
    }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        RuntimeClock.attach(this, engine)
        notifications=NotificationBridge(this,engine)
        widgetChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "dev.gomimap.gomimap/home_widget")
        widgetChannel!!.setMethodCallHandler { call, result ->
            val manager = AppWidgetManager.getInstance(this)
            when (call.method) {
                "available" -> result.success(true)
                "pinSupported" -> result.success(Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported)
                "isAdded" -> result.success(GarbageWidgetProvider.ids(this).isNotEmpty())
                "consumeLaunch" -> { result.success(intent.getBooleanExtra(GarbageWidgetProvider.OPEN, false)); intent.removeExtra(GarbageWidgetProvider.OPEN) }
                "requestPin" -> {
                    if (Build.VERSION.SDK_INT < 26 || !manager.isRequestPinAppWidgetSupported) result.success(false)
                    else {
                        val callback = PendingIntent.getBroadcast(this, 73,
                            Intent(this, GarbageWidgetProvider::class.java).setAction(GarbageWidgetProvider.PINNED),
                            PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
                        val extras = Bundle().apply { putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, GarbageWidgetProvider.preview(this@MainActivity)) }
                        val accepted = try { manager.requestPinAppWidget(GarbageWidgetProvider.component(this), extras, callback) }
                            catch (_: IllegalStateException) { false }
                        result.success(accepted)
                    }
                }
                "publish" -> {
                    val text = call.arguments as? String
                    if (text == null) result.success(false)
                    else GarbageWidgetProvider.executor.execute {
                        val success = try { GarbageWidgetData.save(this, text); true } catch (_: Exception) { false }
                        runOnUiThread { GarbageWidgetProvider.updateAll(this); result.success(success) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifications?.newIntent()
        if (RuntimeClock.consume(this, intent)) {
            RuntimeClock.notifyChanged(this)
            GarbageWidgetProvider.updateAll(this)
        }
        if (intent.getBooleanExtra(GarbageWidgetProvider.OPEN, false)) {
            widgetChannel?.invokeMethod("openToday", null)
            intent.removeExtra(GarbageWidgetProvider.OPEN)
        }
    }
    override fun onRequestPermissionsResult(requestCode:Int,permissions:Array<out String>,grantResults:IntArray) {
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        notifications?.permissionResult(requestCode)
    }
}
