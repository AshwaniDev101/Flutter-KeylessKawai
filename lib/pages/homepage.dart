import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keyless Kawai')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 40, color: Colors.deepOrange),
            ElevatedButton(onPressed: () {}, child: Text("Unlock")),
          ],
        ),
      ),
    );
  }
}
