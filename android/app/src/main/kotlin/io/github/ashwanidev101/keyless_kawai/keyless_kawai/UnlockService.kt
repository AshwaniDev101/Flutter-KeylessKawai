package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class UnlockService : Service() {

    companion object {
        private const val TAG = "UnlockService"
        private const val CHANNEL_ID = "unlock_channel"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate called")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                1,
                createNotification(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(1, createNotification())
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        // Read string, check if null, AND check if empty to safely fallback to LOCK_TRIGGER
        val rawCmd = intent?.getStringExtra("CMD")
        val cmd = if (rawCmd.isNullOrEmpty()) "LOCK_TRIGGER" else rawCmd

        Log.d(TAG, "onStartCommand triggered with verified CMD: $cmd")

        WebSocketManager.sendOnce(cmd) {
            Log.d(TAG, "Transaction complete. Safely killing background service context.")
            stopSelf()
        }

        return START_NOT_STICKY
    }
    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Unlock Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Handles background IoT device actions"
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Keyless Kawaii")
            .setContentText("Executing background request...")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}