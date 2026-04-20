package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class KeylessWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "KeylessWidget"

        const val ACTION_BUTTON_UNLOCK = "KEYLESS_ACTION_UNLOCK"
        const val ACTION_ICON_UNLOCK = "ACTION_ICON"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {

        val unlockBtnIntent = Intent(context, KeylessWidgetProvider::class.java).apply {
            action = ACTION_BUTTON_UNLOCK
        }

        val unlockIconIntent = Intent(context, KeylessWidgetProvider::class.java).apply {
            action = ACTION_ICON_UNLOCK
        }

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

        val views = RemoteViews(
            context.packageName,
            R.layout.keyless_widget
        )

        views.setOnClickPendingIntent(R.id.unlock_btn, unlockBtnPendingIntent)
        views.setOnClickPendingIntent(R.id.unlock_icon, unlockIconPendingIntent)

        appWidgetIds.forEach {
            appWidgetManager.updateAppWidget(it, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        Log.d(TAG, "onReceive triggered")

        val pendingResult = goAsync()

        Thread {
            try {
                when (intent.action) {

                    ACTION_BUTTON_UNLOCK -> {
                        Log.d(TAG, "BUTTON pressed")
//                        startUnlockService(context)
                        startUnlockService(context, "H")
                    }

                    ACTION_ICON_UNLOCK -> {
                        Log.d(TAG, "ICON pressed")
//                        startUnlockService(context)
                        startUnlockService(context, "L")
                    }
                }
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun startUnlockService(context: Context, command: String) {
        val serviceIntent = Intent(context, UnlockService::class.java).apply {
            putExtra("CMD", command) //
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

//    private fun startUnlockService(context: Context) {
//        val serviceIntent = Intent(context, UnlockService::class.java)
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            context.startForegroundService(serviceIntent)
//        } else {
//            context.startService(serviceIntent)
//        }
//    }
}