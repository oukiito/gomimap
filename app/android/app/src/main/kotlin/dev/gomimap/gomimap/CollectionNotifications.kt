// SPDX-License-Identifier: GPL-3.0-or-later
package dev.gomimap.gomimap

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream

/** Only this app's collection reservations; never changes other apps/settings. */
object CollectionNotifications {
    const val CHANNEL = "collection_reminders"
    const val OPEN = "gomimap.notification.open"
    const val TAG = "gomimap-collection"
    const val TEST_ID = 39000
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    private fun alarm(context: Context) = context.getSystemService(AlarmManager::class.java)
    private fun file(context: Context) = File(context.filesDir, "notifications/current.json")
    fun qa(context: Context) = context.packageName == "dev.gomimap.gomimap.qa"
    fun permission(context: Context): String {
        val enabled = manager(context).areNotificationsEnabled() && (Build.VERSION.SDK_INT < 26 ||
            manager(context).getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return if(context.getSharedPreferences("NotificationPermission",0).getBoolean("requested",false)) "denied" else "notDetermined"
        }
        return if(enabled) "allowed" else "denied"
    }
    fun read(context: Context): JSONObject? = try {
        val f=file(context); require(f.length() in 1..524288)
        val root=JSONObject(f.readText()); validate(root.getJSONObject("plan")); require(root.getLong("generation")>=1);root
    } catch(_:Exception) { null }
    private fun write(context: Context, root: JSONObject) {
        val f=file(context);f.parentFile!!.mkdirs();val pending=File(f.parentFile,"pending.json")
        FileOutputStream(pending).use {it.write(root.toString().toByteArray(Charsets.UTF_8));it.fd.sync()}
        android.system.Os.rename(pending.path,f.path)
    }
    fun validate(plan: JSONObject) {
        require(plan.toString().toByteArray(Charsets.UTF_8).size<=524288)
        require(plan.getInt("schemaVersion")==1 && plan.getString("municipalityId")=="demo-toshima")
        require(plan.getString("areaId") in setOf("a","b") && plan.getString("locale") in GarbageWidgetData.supported)
        plan.getBoolean("fixture")
        require(plan.getString("channelName").length in 1..200 && plan.getString("testTitle").length in 1..1000)
        val entries=plan.getJSONArray("entries");require(entries.length()<=28)
        val ids=mutableSetOf<Int>()
        for(i in 0 until entries.length()) {
            val e=entries.getJSONObject(i);require(e.getInt("id") in 1..28 && ids.add(e.getInt("id")))
            val due=e.getLong("due");val end=e.getLong("expires")
            require(due>=0 && due<end && end<=253402300799999L)
            WidgetDate.parse(e.getString("date"));require(e.getString("kind") in setOf("morning","evening"))
            for(k in listOf("title","areaLabel","separator")) require(e.getString(k).length in 1..2000)
            val rows=e.getJSONArray("collections");require(rows.length() in 1..32)
            for(j in 0 until rows.length()) {val row=rows.getJSONObject(j);require(row.getString("name").length in 1..1000 && row.getString("detail").length in 1..2000 && row.getLong("deadline")>due)}
        }
    }
    fun matches(context: Context, plan: JSONObject): Boolean = try {
        plan.getString("areaId")==GarbageWidgetData.confirmedArea(context) &&
            plan.optString("datasetVersion")==GarbageWidgetData.activeVersion(context) &&
            plan.getString("locale")==GarbageWidgetData.currentLanguage(context)
    } catch(_:Exception) {false}
    private fun intent(context: Context, generation: Long, id: Int) = Intent(context, CollectionNotificationReceiver::class.java)
        .setAction("gomimap.collection.deliver").setData(Uri.parse("gomimap-notification://reservation/$generation/$id"))
        .putExtra("generation",generation).putExtra("id",id)
    private fun pending(context: Context,generation:Long,id:Int,existing:Boolean=false): PendingIntent? = PendingIntent.getBroadcast(
        context,id,intent(context,generation,id),PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_ONE_SHOT or
            if(existing)PendingIntent.FLAG_NO_CREATE else PendingIntent.FLAG_UPDATE_CURRENT)
    @Synchronized fun pause(context: Context): Boolean = try {
        val root=read(context)
        if(root!=null) {val entries=root.getJSONObject("plan").getJSONArray("entries");for(i in 0 until entries.length()) {
            val id=entries.getJSONObject(i).getInt("id");val token=pending(context,root.getLong("generation"),id,true)
            if(token!=null){alarm(context).cancel(token);token.cancel()}
            manager(context).cancel(TAG,30000+id)
            check(pending(context,root.getLong("generation"),id,true)==null)
        }}
        manager(context).cancel(TAG,TEST_ID)
        if(root!=null){root.put("paused",true);write(context,root)}
        true
    } catch(_:Exception){false}
    @Synchronized fun apply(context: Context,text:String): Boolean {
        val plan=try {JSONObject(text).also {validate(it)
        // Current product loader contains only fixtures. Real-data scheduling
        // needs its publication gate; non-empty test plans belong to QA only.
        require(it.getJSONArray("entries").length()==0 || qa(context))
        require(it.getJSONArray("entries").length()==0 || matches(context,it))
        }}catch(_:Exception){return false} // Invalid candidates never cancel a valid plan.
        return try {
        val generation=(read(context)?.getLong("generation")?:0)+1
        require(generation>0 && pause(context))
        val root=JSONObject().put("generation",generation).put("paused",false).put("plan",plan)
        write(context,root) // Journal all IDs before any partial OS registration.
        restore(context)
        true
        } catch(_:Exception) {pause(context);false}
    }
    @Synchronized fun restore(context: Context) {
        val root=read(context)?:return;val plan=root.getJSONObject("plan")
        if(root.optBoolean("paused") || !matches(context,plan) || permission(context)!="allowed") {pause(context);return}
        if(RuntimeClock.frozen(context))return // QA preview; never claim an alarm was registered.
        val now=RuntimeClock.now(context);val entries=plan.getJSONArray("entries")
        for(i in 0 until entries.length()) {val e=entries.getJSONObject(i)
            if(e.getLong("due")>now && e.getLong("expires")>now) {
                alarm(context).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,e.getLong("due"),pending(context,root.getLong("generation"),e.getInt("id"))!!)
            }
        }
    }
    fun status(context: Context): Map<String,Any> {
        val root=read(context);val preview=qa(context)&&RuntimeClock.frozen(context)
        val future=mutableListOf<JSONObject>()
        if(root!=null && !root.optBoolean("paused") && matches(context,root.getJSONObject("plan"))) {
            val entries=root.getJSONObject("plan").getJSONArray("entries");val now=RuntimeClock.now(context)
            for(i in 0 until entries.length()) {val e=entries.getJSONObject(i);if(e.getLong("due")>now && e.getLong("expires")>now)future.add(e)}
        }
        val count=if(preview || permission(context)!="allowed")0 else future.count {pending(context,root!!.getLong("generation"),it.getInt("id"),true)!=null}
        return mapOf("permission" to permission(context),"preview" to preview,"count" to count,"planCount" to future.size,
            "nextDue" to (future.minOfOrNull{it.getLong("due")}?:0L),"generation" to (root?.getLong("generation")?:0L))
    }
    fun deliverable(plan:JSONObject,e:JSONObject,now:Long): Boolean {
        if(now<e.getLong("due") || now>=e.getLong("expires"))return false
        val today=WidgetDate.today(now)
        return e.getString("date")== (if(e.getString("kind")=="evening")today.plusDays(1) else today).toString()
    }
    @Synchronized fun deliver(context:Context,generation:Long,id:Int) {
        val root=read(context)?:return;val plan=root.getJSONObject("plan")
        if(root.getLong("generation")!=generation || root.optBoolean("paused") || !matches(context,plan) || permission(context)!="allowed")return
        val entries=plan.getJSONArray("entries")
        for(i in 0 until entries.length()) {val e=entries.getJSONObject(i)
            if(e.getInt("id")==id && deliverable(plan,e,RuntimeClock.now(context)))post(context,plan,e,false)
        }
    }
    fun test(context:Context): Boolean {
        if(!qa(context) || permission(context)!="allowed")return false
        val root=read(context)?:return false;val plan=root.getJSONObject("plan")
        if(root.optBoolean("paused") || !matches(context,plan) || plan.getJSONArray("entries").length()==0)return false
        post(context,plan,plan.getJSONArray("entries").getJSONObject(0),true);return true
    }
    private fun post(context:Context,plan:JSONObject,e:JSONObject,test:Boolean) {
        val list=mutableListOf<JSONObject>();val rows=e.getJSONArray("collections");val now=RuntimeClock.now(context)
        for(i in 0 until rows.length()) {val row=rows.getJSONObject(i);if(test || e.getString("kind")=="evening" || row.getLong("deadline")>now)list.add(row)}
        if(list.isEmpty())return
        if(Build.VERSION.SDK_INT>=26)manager(context).createNotificationChannel(NotificationChannel(CHANNEL,plan.getString("channelName"),NotificationManager.IMPORTANCE_DEFAULT))
        val target=JSONObject().put("date",e.getString("date")).put("areaId",plan.getString("areaId")).put("datasetVersion",plan.optString("datasetVersion"))
        val open=Intent(context,MainActivity::class.java).putExtra(OPEN,target.toString()).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val click=PendingIntent.getActivity(context,if(test)TEST_ID else 30000+e.getInt("id"),open,PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val title=if(test)plan.getString("testTitle").replace("{title}",e.getString("title")) else e.getString("title")
        val body=e.getString("areaLabel")+"\n"+list.joinToString(e.getString("separator")){it.getString("name")}+"\n"+list.joinToString("\n"){it.getString("detail")}
        val builder=if(Build.VERSION.SDK_INT>=26)Notification.Builder(context,CHANNEL) else Notification.Builder(context)
        val notification=builder.setSmallIcon(R.drawable.notification_small).setContentTitle(title).setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body)).setContentIntent(click).setAutoCancel(true).build()
        manager(context).notify(TAG,if(test)TEST_ID else 30000+e.getInt("id"),notification)
    }
}

class CollectionNotificationReceiver:BroadcastReceiver() {
    override fun onReceive(context:Context,intent:Intent) {
        val result=goAsync();GarbageWidgetProvider.executor.execute {
            try {if(intent.action=="gomimap.collection.deliver")CollectionNotifications.deliver(context,intent.getLongExtra("generation",-1),intent.getIntExtra("id",-1))
                else CollectionNotifications.restore(context)
            } finally {result.finish()}
        }
    }
}
