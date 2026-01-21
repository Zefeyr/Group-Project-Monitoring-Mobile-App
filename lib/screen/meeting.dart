import 'package:flutter/material.dart';

class MeetingPage extends StatelessWidget {
  const MeetingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_audio, size: 80, color: Colors.blue),
          const Text(
            "Scanning for nearby teammates...",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Check-In to Meeting"),
          ),
        ],
      ),
    );
  }
}
