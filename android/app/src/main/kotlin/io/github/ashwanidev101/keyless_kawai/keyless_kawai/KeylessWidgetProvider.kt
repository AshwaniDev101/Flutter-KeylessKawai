package io.github.ashwanidev101.keyless_kawai.keyless_kawai


// Core widget APIs.
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log

// Required to give the widget permission to trigger actions.
import android.app.PendingIntent
// Used to send a broadcast when button is clicked.
import android.content.Intent
// Widgets cannot access real Views → only this “proxy view”.
import android.widget.RemoteViews
import io.github.ashwanidev101.keyless_kawai.keyless_kawai.KeylessWidgetProvider.Companion.ACTION_UNLOCK


// AppWidgetProvider is a broadcast receiver provided by Android
// It listens to widget lifecycle events sent by the system.
// This class does not draw UI directly. It controls the widget using RemoteViews.

// Android calls it when:
// - widget is added
// - widget updates
// - widget button is pressed
class KeylessWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_UNLOCK = "KEYLESS_ACTION_UNLOCK"
    }

    // 'onUpdate' Called when:
    // - Widget is added
    // - Widget refreshes
    // - Device reboot
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {


        // Intent (what happens on click)
        // This says: Send a broadcast Back to this same widget provider With action = KEYLESS_ACTION_UNLOCK
        val intent = Intent(context, KeylessWidgetProvider::class.java).apply {
            action = ACTION_UNLOCK
        }


        // PendingIntent?
        // Widgets run outside your app, They need permission to call back into your app
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Widgets cannot use real Views — only RemoteViews
        val views = RemoteViews(
            context.packageName,
            R.layout.keyless_widget
        )

        // Attach click to button
        views.setOnClickPendingIntent(R.id.btn_unlock, pendingIntent)


        //Update the widget and Pushes the RemoteViews to the launcher.
        appWidgetIds.forEach {
            appWidgetManager.updateAppWidget(it, views)
        }


    }


    // Widget Button → PendingIntent → Broadcast → Provider → Real logic
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_UNLOCK) {
            val serviceIntent = Intent(context, UnlockService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

                // API 24–25
                context.startForegroundService(serviceIntent)
            } else {

                // API 26+
                context.startService(serviceIntent)
            }

        }
    }


}