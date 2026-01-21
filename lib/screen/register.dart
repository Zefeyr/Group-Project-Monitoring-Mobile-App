import 'package:flutter/material.dart';
import '../main.dart'; // To navigate to MainNavigation after successful registration

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = 'Student'; // Default role

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Join CollabQuest",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Full Name Field
            const TextField(
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email Field
            const TextField(
              decoration: InputDecoration(
                labelText: "University Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password Field
            const TextField(
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Role Selection (Crucial for your Accountability Score logic)
            const Text(
              "Register as:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Student"),
                    value: "Student",
                    groupValue: _selectedRole,
                    onChanged: (value) =>
                        setState(() => _selectedRole = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Lecturer"),
                    value: "Lecturer",
                    groupValue: _selectedRole,
                    onChanged: (value) =>
                        setState(() => _selectedRole = value!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Register Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Future Logic: Firebase Auth Registration
                // For now, navigate to the Main app
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Register"),
            ),

            const SizedBox(height: 16),

            // Back to Login
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login here"),
            ),
          ],
        ),
      ),
    );
  }
}
