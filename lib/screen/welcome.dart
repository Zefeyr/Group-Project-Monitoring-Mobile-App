import 'package:flutter/material.dart';
import 'login.dart'; // Import the login file so we can go there

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch,
              size: 80,
              color: Colors.blue,
            ), // Placeholder for logo
            const Text(
              "CollabQuest",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text("Level up your group projects"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("Get Started"),
            ),
          ],
        ),
      ),
    );
  }
}
