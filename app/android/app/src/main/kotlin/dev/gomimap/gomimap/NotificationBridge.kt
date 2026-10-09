// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class NotificationBridge(private val activity:MainActivity,engine:FlutterEngine) {
    private val channel=MethodChannel(engine.dartExecutor.binaryMessenger,"dev.gomimap.gomimap/notifications")
    private var permissionResult:MethodChannel.Result?=null
    init {
        channel.setMethodCallHandler {call,result ->
            when(call.method) {
                "available"->result.success(true)
                "status"->result.success(CollectionNotifications.status(activity))
                "requestPermission"->{
                    if(CollectionNotifications.permission(activity)=="allowed" || Build.VERSION.SDK_INT<33)result.success(CollectionNotifications.permission(activity))
                    else if(permissionResult!=null)result.error("busy","Permission request pending",null)
                    else {permissionResult=result;activity.getSharedPreferences("NotificationPermission",0).edit().putBoolean("requested",true).apply();activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),REQUEST)}
                }
                "pause","apply"->{GarbageWidgetProvider.executor.execute {
                    val ok=if(call.method=="pause")CollectionNotifications.pause(activity) else
                        (call.arguments as? String)?.let {CollectionNotifications.apply(activity,it)}?:false
                    activity.runOnUiThread{result.success(ok)}
                }}
                "test"->result.success(CollectionNotifications.test(activity))
                "openSettings"->{
                    val intent=if(Build.VERSION.SDK_INT>=26)Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,activity.packageName)
                        else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:${activity.packageName}"))
                    activity.startActivity(intent);result.success(null)
                }
                "consumeLaunch"->result.success(consume())
                else->result.notImplemented()
            }
        }
    }
    private fun consume():Map<String,Any>? {
        val text=activity.intent.getStringExtra(CollectionNotifications.OPEN)?:return null
        activity.intent.removeExtra(CollectionNotifications.OPEN)
        return try {val value=JSONObject(text);WidgetDate.parse(value.getString("date"));
            mapOf("date" to value.getString("date"),"areaId" to value.getString("areaId"),"datasetVersion" to value.getString("datasetVersion"))
        } catch(_:Exception){null}
    }
    fun newIntent(){consume()?.let {channel.invokeMethod("open",it)}}
    fun permissionResult(request:Int):Boolean {
        if(request!=REQUEST)return false
        permissionResult?.success(CollectionNotifications.permission(activity));permissionResult=null;return true
    }
    companion object {const val REQUEST=814}
}
