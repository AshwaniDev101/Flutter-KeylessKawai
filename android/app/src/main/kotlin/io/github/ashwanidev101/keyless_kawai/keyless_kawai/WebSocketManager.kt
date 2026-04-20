package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.util.Log
import okhttp3.*
import java.util.concurrent.TimeUnit

object WebSocketManager {

    private const val TAG = "WebSocket"
    private const val ESP_URL = "ws://192.168.1.200:81"

    private val client = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS) // required for WS
        .build()

    fun sendOnce(command: String) {

        Log.d(TAG, "sendOnce → Connecting")

        val request = Request.Builder()
            .url(ESP_URL)
            .build()

        val listener = object : WebSocketListener() {

            override fun onOpen(ws: WebSocket, response: Response) {
                Log.d(TAG, "Connected → sending $command")

                ws.send(command)

                // 🔥 close immediately after sending
                ws.close(1000, "done")
            }

            override fun onMessage(ws: WebSocket, text: String) {
                Log.d(TAG, "Response: $text")
            }

            override fun onClosing(ws: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "Closing: $code $reason")
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "Error", t)
            }
        }

        client.newWebSocket(request, listener)
    }
}