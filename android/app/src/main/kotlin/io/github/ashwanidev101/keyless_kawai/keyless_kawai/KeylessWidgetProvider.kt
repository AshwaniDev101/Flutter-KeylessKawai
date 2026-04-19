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


// AppWidgetProvider is a broadcast receiver provided by Android
// It listens to widget lifecycle events sent by the system.
// This class does not draw UI directly. It controls the widget using RemoteViews.

// Android calls it when:
// - widget is added
// - widget updates
// - widget button is pressed
class KeylessWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_BUTTON_UNLOCK = "KEYLESS_ACTION_UNLOCK"
        const val ACTION_ICON_UNLOCK = "ACTION_ICON"
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

        val unlockBtnIntent = Intent(context, KeylessWidgetProvider::class.java).apply {
            action = ACTION_BUTTON_UNLOCK
        }

        val unlockIconIntent = Intent(context, KeylessWidgetProvider::class.java).apply {
            action = ACTION_ICON_UNLOCK
        }


        // PendingIntent?
        // Widgets run outside your app, They need permission to call back into your app
        val unlockBtnPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            unlockBtnIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val unlockIconPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            unlockIconIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Widgets cannot use real Views — only RemoteViews
        val views = RemoteViews(
            context.packageName,
            R.layout.keyless_widget
        )


        // Attaching Function to Layout
        // Button click
        views.setOnClickPendingIntent(R.id.unlock_btn, unlockBtnPendingIntent)

        // Image click
        views.setOnClickPendingIntent(R.id.unlock_icon, unlockIconPendingIntent)



        //Update the widget and Pushes the RemoteViews to the launcher.
        appWidgetIds.forEach {
            appWidgetManager.updateAppWidget(it, views)
        }


    }


    // Widget Button → PendingIntent → Broadcast → Provider → Real logic
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

//        Log.d("===", "onReceive")


        when (intent.action) {

            ACTION_BUTTON_UNLOCK -> {
                Log.d("===", "BUTTON pressed")

                WebSocketManager.sendH();

//                startService(context, "H")
            }

            ACTION_ICON_UNLOCK-> {
                Log.d("===", "ICON pressed")
                WebSocketManager.sendL();
//                startService(context, "L")
            }
        }

//        if (intent.action == ACTION_UNLOCK) {
//
//            Log.d("===", "ACTION_UNLOCK")
//
//            val serviceIntent = Intent(context, UnlockService::class.java)
//            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
//
//                // API 24–25
//                context.startForegroundService(serviceIntent)
//            } else {
//
//                // API 26+
//                context.startService(serviceIntent)
//            }
//
//        }
    }


}