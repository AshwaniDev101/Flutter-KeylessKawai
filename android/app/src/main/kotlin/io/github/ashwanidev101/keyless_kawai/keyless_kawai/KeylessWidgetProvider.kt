package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

//AppWidgetProvider is a broadcast receiver provided by Android
//It listens to widget lifecycle events sent by the system.
//This class does not draw UI directly. It controls the widget using RemoteViews.

class KeylessWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_UNLOCK = "KEYLESS_ACTION_UNLOCK"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {

            val views = RemoteViews(
                context.packageName,
                R.layout.keyless_widget
            )

            val intent = Intent(context, KeylessWidgetProvider::class.java).apply {
                action = ACTION_UNLOCK
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.btn_unlock, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_UNLOCK) {
            Log.d("KeylessWidget", "UNLOCK pressed from widget")
        }
    }
}