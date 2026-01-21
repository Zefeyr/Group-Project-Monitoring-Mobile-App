import 'package:flutter/material.dart';
// Note: We will link this back to the MainNavigation in main.dart
import '../main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // This clears the navigation stack so user can't "back" into login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigation(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("Sign In"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
