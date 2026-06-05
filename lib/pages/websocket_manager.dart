import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketManager {
  static const String _espUrl = "ws://192.168.1.200:81";

  // Fires command string and returns the mirrored data payload response
  static Future<String?> sendOnce(String command) async {
    if (kDebugMode) print("WebSocketManager: Fast-firing '$command'...");

    try {
      final uri = Uri.parse(_espUrl);
      final channel = WebSocketChannel.connect(uri);
      final WebSocketSink sink = channel.sink;

      sink.add(command);

      // Wait for the incoming mirror response message packet from the socket stream
      final String response = await channel.stream.first.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => "",
      );

      // Graceful socket teardown allocation post transmission flush window
      await Future.delayed(const Duration(milliseconds: 50));
      sink.close(status.normalClosure);

      return response.isNotEmpty ? response : null;
    } catch (e) {
      if (kDebugMode) print("WebSocketManager Fire Exception caught: $e");
      return null;
    }
  }
}