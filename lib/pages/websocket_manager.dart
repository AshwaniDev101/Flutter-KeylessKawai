import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketManager {
  // Target ESP8266 Endpoint
  static const String _espUrl = "ws://192.168.1.200:81";

  static Future<void> sendOnce(String command, {Function(String)? onResponse}) async {
    if (kDebugMode) print("WebSocketManager: Connecting to deliver '$command'...");

    try {
      final uri = Uri.parse(_espUrl);
      final channel = WebSocketChannel.connect(uri);
      final WebSocketSink sink = channel.sink;

      bool receivedMessage = false;

      channel.stream.listen(
            (message) {
          if (kDebugMode) print("WebSocketManager Received Confirmation: $message");
          receivedMessage = true;

          // Forward the raw text string back to our UI callback handler
          if (onResponse != null) {
            onResponse(message.toString());
          }

          if (kDebugMode) print("Transaction confirmed by ESP. Closing socket safely.");
          sink.close(status.normalClosure);
        },
        onError: (error) {
          if (kDebugMode) print("WebSocketManager Network Error: $error");
          if (onResponse != null) onResponse("ERROR");
        },
        onDone: () {
          if (kDebugMode) print("WebSocketManager Status: Connection cycle finished.");
          // Fallback if socket closes without a clear payload string response
          if (!receivedMessage && onResponse != null) onResponse("DONE");
        },
        cancelOnError: true,
      );

      sink.add(command);

    } catch (e) {
      if (kDebugMode) print("WebSocketManager Exception caught: $e");
      if (onResponse != null) onResponse("ERROR");
    }
  }
}