import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketManager {
  // Target ESP8266 Endpoint
  static const String _espUrl = "ws://192.168.1.200:81";

  static Future<void> sendOnce(String command) async {
    if (kDebugMode) print("WebSocketManager: Connecting to deliver '$command'...");

    try {
      final uri = Uri.parse(_espUrl);
      final channel = WebSocketChannel.connect(uri);

      // We explicitly pull a reference to the sink to keep control over it
      final WebSocketSink sink = channel.sink;

      channel.stream.listen(
            (message) {
          if (kDebugMode) print("WebSocketManager Received Confirmation: $message");

          // Exactly like Kotlin's onMessage block:
          // The ESP8266 replied, so it definitely processed our payload. Safe to close now!
          if (kDebugMode) print("Transaction confirmed by ESP. Closing socket safely.");
          sink.close(status.normalClosure);
        },
        onError: (error) {
          if (kDebugMode) print("WebSocketManager Network Error: $error");
        },
        onDone: () {
          if (kDebugMode) print("WebSocketManager Status: Connection cycle finished.");
        },
        cancelOnError: true,
      );

      // Transmit the raw data string down the active sink
      sink.add(command);

    } catch (e) {
      if (kDebugMode) print("WebSocketManager Exception caught: $e");
    }
  }
}