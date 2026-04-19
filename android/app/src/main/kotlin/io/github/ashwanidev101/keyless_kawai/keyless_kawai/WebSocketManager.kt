package io.github.ashwanidev101.keyless_kawai.keyless_kawai

import android.util.Log
import okhttp3.*

object WebSocketManager {

    private const val TAG = "==="
    private const val ESP_URL = "ws://192.168.1.200:81"

    private val client = OkHttpClient()
    private var webSocket: WebSocket? = null

    var isConnected = false
        private set

    fun init() {
        Log.d(TAG, "init called. Connecting to $ESP_URL")

        val request = Request.Builder()
            .url(ESP_URL)
            .build()



        val listener = object : WebSocketListener() {

            override fun onOpen(webSocket: WebSocket, response: Response) {
                this@WebSocketManager.webSocket = webSocket
                isConnected = true
                Log.d(TAG, "Connected")
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                Log.d(TAG, "Message received: $text")
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "Closing connection: $code $reason")

                this@WebSocketManager.webSocket = null
                isConnected = false

                webSocket.close(1000, null)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                isConnected = false
                this@WebSocketManager.webSocket = null

                Log.e(TAG, "Connection failed", t)
                Log.e(TAG, "Response: ${response?.message}")
            }
        }

        client.newWebSocket(request, listener)
    }

    fun sendH() {
        if (!isConnected) {
            Log.e(TAG, "sendH failed: not connected")
            return
        }

        Log.d(TAG, "Sending H")
        webSocket?.send("H")
    }

    fun sendL() {
        if (!isConnected) {
            Log.e(TAG, "sendL failed: not connected")
            return
        }

        Log.d(TAG, "Sending L")
        webSocket?.send("L")
    }

    fun close() {
        Log.d(TAG, "Closing connection")

        isConnected = false
        webSocket?.close(1000, "closed by app")
        webSocket = null
    }
}