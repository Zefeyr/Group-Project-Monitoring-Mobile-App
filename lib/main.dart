import 'package:flutter/material.dart';

// 1. Corrected imports to match your actual filenames
import 'screen/welcome.dart';
import 'screen/home.dart';
import 'screen/task.dart';
import 'screen/chat.dart';
import 'screen/review.dart';
import 'screen/meeting.dart';
import 'screen/profilesettings.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Ensure WelcomeScreen class exists in welcome.dart
      home: const WelcomeScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 2. IMPORTANT: These Class names must match the 'class X extends...'
  // inside your screen files. I have updated them to what is likely there.
  final List<Widget> _pages = [
    const HomePage(), // Inside home.dart
    const TaskBoardPage(), // Inside task.dart
    const ChatPage(), // Inside chat.dart
    const ReviewPage(), // Inside review.dart
    const MeetingPage(), // Inside meeting.dart
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CollabQuest',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                // Matches the class inside profilesettings.dart
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.thumbs_up_down),
            label: 'Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Meeting',
          ),
        ],
      ),
    );
  }
}
