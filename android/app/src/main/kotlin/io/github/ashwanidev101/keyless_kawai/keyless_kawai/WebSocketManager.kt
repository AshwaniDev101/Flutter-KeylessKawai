package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.util.Log
import okhttp3.*

object WebSocketManager {

    private const val TAG = "WebSocket"
    private const val ESP_URL = "ws://192.168.1.200:81"

    private val client = OkHttpClient()
    private var webSocket: WebSocket? = null

    var isConnected = false
        private set

    fun connect(onConnected: (() -> Unit)? = null) {
        Log.d(TAG, "Connecting to $ESP_URL")

        val request = Request.Builder()
            .url(ESP_URL)
            .build()

        val listener = object : WebSocketListener() {

            override fun onOpen(ws: WebSocket, response: Response) {
                webSocket = ws
                isConnected = true

                Log.d(TAG, "Connected")

                onConnected?.invoke() // 🔥 IMPORTANT
            }

            override fun onMessage(ws: WebSocket, text: String) {
                Log.d(TAG, "Message: $text")
            }

            override fun onClosing(ws: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "Closing: $code $reason")

                isConnected = false
                webSocket = null

                ws.close(1000, null)
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                isConnected = false
                webSocket = null

                Log.e(TAG, "Error", t)
            }
        }

        client.newWebSocket(request, listener)
    }

    fun send(command: String) {
        if (!isConnected) {
            Log.e(TAG, "Not connected. Cannot send: $command")
            return
        }

        Log.d(TAG, "Sending: $command")
        webSocket?.send(command)
    }

    fun close() {
        Log.d(TAG, "Closing connection")

        isConnected = false
        webSocket?.close(1000, "closed by app")
        webSocket = null
    }
}