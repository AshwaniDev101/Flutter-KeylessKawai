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
import java.net.Socket


// This is an Android Service.
// A Service: Has no UI, Can run when app is closed, Can run when phone is

// Widget → Service → Local WebSocket / TCP → Door
class UnlockService : Service() {

    override fun onCreate() {
        super.onCreate()
        startForeground(1, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        Thread {
            try {
                sendUnlockSignal()
            } catch (e: Exception) {
                Log.e("UnlockService", "Unlock failed", e)
            } finally {
                stopSelf()
            }
        }.start()

        return START_NOT_STICKY
    }

    private fun sendUnlockSignal() {
        // LOCAL NETWORK ONLY
        val socket = Socket("192.168.1.50", 8080)

        socket.getOutputStream().use {
            it.write("UNLOCK\n".toByteArray())
            it.flush()
        }

        socket.close()
        Log.d("UnlockService", "Unlock signal sent")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(): Notification {
        val channelId = "unlock_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Unlock Service",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Keyless")
            .setContentText("Unlocking door…")
            .setSmallIcon(R.drawable.ic_notification_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
