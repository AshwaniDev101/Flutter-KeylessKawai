import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keyless Kawai'),centerTitle: true,),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 60, color: Colors.deepOrange),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: () {}, child: Text("Unlock",style: TextStyle(fontSize: 20)),),
          ],
        ),
      ),
    );
  }
}
