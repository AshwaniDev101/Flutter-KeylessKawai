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
        private const val TAG = "==="
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

        val cmd = intent?.getStringExtra("CMD") ?: "H" // default fallback

        Log.d(TAG, "onStartCommand triggered with CMD: $cmd")

        Thread {
            try {
                Log.d(TAG, "Thread started")

                WebSocketManager.connect {
                    WebSocketManager.send(cmd) // 🔥 dynamic now
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error occurred", e)
            } finally {
                Log.d(TAG, "Stopping service")
                stopSelf()
            }
        }.start()

        return START_NOT_STICKY
    }
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//
//        Log.d(TAG, "onStartCommand triggered")
//
//        Thread {
//            try {
//                Log.d(TAG, "Thread started")
//
//                // Simulate some work
//                Thread.sleep(1000)
//
//                Log.d(TAG, "TEST: Unlock logic would run here")
//
//                WebSocketManager.connect {
//                    WebSocketManager.send("H")
//                }
//
//            } catch (e: Exception) {
//                Log.e(TAG, "Error occurred", e)
//            } finally {
//                Log.d(TAG, "Stopping service")
//                stopSelf()
//            }
//        }.start()
//
//        return START_NOT_STICKY
//    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(): Notification {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Unlock Service",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Keyless")
            .setContentText("Running test service...")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .build()
    }
}