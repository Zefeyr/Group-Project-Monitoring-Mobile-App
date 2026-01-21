import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.green.withOpacity(0.1),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 14, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Messages are end-to-end encrypted",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            reverse: true, // New messages at the bottom
            itemBuilder: (context, index) => ListTile(
              title: const Text("Teammate Name"),
              subtitle: Text("This is message number $index"),
            ),
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notification_important, color: Colors.red),
            onPressed: () {},
          ), // THE BEEP BUTTON
        ],
      ),
    );
  }
}
