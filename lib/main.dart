import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

import 'package:keyless_kawai/pages/homepage.dart';

void main() async {
  // Required so Flutter can talk to the native OS before the app starts
  WidgetsFlutterBinding.ensureInitialized();

  // Check if we are running on a Native Desktop OS (Windows/Mac/Linux)
  // We MUST check !kIsWeb first, because dart:io throws errors on web browsers
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(600, 600),         // Set your exact starting size
      minimumSize: Size(600, 600),  // Prevent shrinking
      maximumSize: Size(600, 600),   // Prevent growing
      center: true,                 // Boot up in the middle of the screen
      title: "Keyless Kawaii",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      // Physically lock the OS window
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Keyless Kawaii",
      home: Homepage(),
    );
  }
}