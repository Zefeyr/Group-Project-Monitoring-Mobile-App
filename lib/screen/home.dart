import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent back button from appearing
        title: Text(
          'CollabQuest',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A3B5D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                 // Smart Auto-Login in main.dart will handle the redirect automatically!
                 // But we can pop to be safe or just let the StreamBuilder do its work.
                 // Actually, since main.dart is wrapper, StreamBuilder will just switch widgets.
                 // So we don't strictly need Navigator.pushReplacement unless we want to reset stack.
                 // Let's rely on main.dart's Smart Navigation, but if we are deep in stack, we might want to pop.
                 // However, StreamBuilder is at the root. So it will replace HomeScreen with WelcomeScreen.
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to CollabQuest!',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
