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

        // Persistent key for storing toggle state safely inside disk cache
        private const val PREFS_NAME = "keyless_widget_prefs"
        private const val KEY_LED_STATE = "led_toggle_state"
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

        Log.d(TAG, "onReceive triggered with action: ${intent.action}")

        // Directly parse intents on the main thread loop.
        // Launching services is incredibly lightweight and doesn't require a background thread.
        when (intent.action) {
            ACTION_BUTTON_UNLOCK -> {
                Log.d(TAG, "Widget Button Pressed -> Triggering Lock")
                startUnlockService(context, "LOCK_TRIGGER")
            }

            ACTION_ICON_UNLOCK -> {
                Log.d(TAG, "Widget Icon Pressed -> Calculating Toggle State")

                // Read persistent value directly from the app storage space
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val currentLedState = prefs.getBoolean(KEY_LED_STATE, false) // default false

                // Determine target command payload string
                val command = if (currentLedState) "LED_OFF" else "LED_ON"
                Log.d(TAG, "Calculated toggle operation: sending -> $command")

                // Dispatch task to our stable foreground service container
                startUnlockService(context, command)

                // Save updated inverted configuration value back to preference disk space
                prefs.edit().putBoolean(KEY_LED_STATE, !currentLedState).apply()
            }
        }
    }

    private fun startUnlockService(context: Context, command: String) {
        val serviceIntent = Intent(context, UnlockService::class.java).apply {
            putExtra("CMD", command)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}