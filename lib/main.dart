import 'package:flutter/material.dart';
import 'screen/welcome.dart'; // Import your new welcome screen

void main() {
  runApp(const CollabQuest());
}

class CollabQuest extends StatelessWidget {
  const CollabQuest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CollabQuest',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // The app starts at the Welcome Screen
      home: const WelcomeScreen(),
    );
  }
}

// This is the "Dashboard" that users see AFTER logging in.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Tasks Screen')),
    const Center(child: Text('Chat Screen')),
    const Center(child: Text('Review Screen')),
    const Center(child: Text('Profile Screen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CollabQuest')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.thumbs_up_down),
            label: 'Review',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
