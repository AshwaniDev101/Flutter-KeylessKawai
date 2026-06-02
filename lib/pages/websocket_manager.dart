import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketManager {
  // Target ESP8266 Endpoint
  static const String _espUrl = "ws://192.168.1.200:81";

  static Future<void> sendOnce(String command) async {
    if (kDebugMode) print("WebSocketManager: Fast-firing '$command'...");

    try {
      final uri = Uri.parse(_espUrl);
      final channel = WebSocketChannel.connect(uri);
      final WebSocketSink sink = channel.sink;

      // 1. Shove payload command string down the active network pipe
      sink.add(command);

      // 2. Give the phone's OS TCP stack a 200ms window to completely flush
      // the packets out of the device before cutting the stream context
      await Future.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) print("Buffer flushed. Closing fire-and-forget socket safely.");
      sink.close(status.normalClosure);

    } catch (e) {
      if (kDebugMode) print("WebSocketManager Fire Exception caught: $e");
    }
  }
}