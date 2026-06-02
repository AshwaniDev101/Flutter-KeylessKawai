package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.os.Handler
import android.os.Looper
import android.util.Log
import okhttp3.*
import java.util.concurrent.TimeUnit

object WebSocketManager {

    private const val TAG = "WebSocket"
    private const val ESP_URL = "ws://192.168.1.200:81"

    private val client = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()

    fun sendOnce(command: String, onComplete: () -> Unit) {

        Log.d(TAG, "sendOnce → Connecting to deliver: $command")

        val request = Request.Builder()
            .url(ESP_URL)
            .build()

        val listener = object : WebSocketListener() {

            override fun onOpen(ws: WebSocket, response: Response) {
                Log.d(TAG, "Connected → Shifting command to network buffer")

                // 1. Shove payload into network queue
                ws.send(command)

                // 2. Increased to 350ms to guarantee slower phone antennas fully flush the packet
                Handler(Looper.getMainLooper()).postDelayed({
                    Log.d(TAG, "Buffer flushed. Closing connection context safely.")
                    ws.close(1000, "Done")
                    onComplete()
                }, 350)
            }

            override fun onClosing(ws: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "Closing: $code / $reason")
            }

            override fun onClosed(ws: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "Socket closed.")
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "Network delivery failure: ${t.message}", t)
                onComplete()
            }
        }

        client.newWebSocket(request, listener)
    }
}