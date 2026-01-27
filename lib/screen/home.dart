import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'project.dart';
import 'createproject.dart';
import 'profile.dart'; 
import 'task.dart';
import 'chat.dart';
import 'notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedFilter = 'All'; // Filter state: 'All', 'Leader', 'Member'
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryBlue = const Color(0xFF1A3B5D);
  final Color accentBlue = const Color(0xFF3F6D9F);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(),
      const TaskScreen(),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: const Color(0xFFF8F9FA),
      // drawer removed
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildNotificationIcon(), // Notification Icon triggers Drawer
        centerTitle: true,
        title: Text(
          'CollabQuest',
          style: GoogleFonts.outfit(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateProjectScreen(),
                ),
              ),
              backgroundColor: primaryBlue,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- NOTIFICATION WIDGETS ---

  Widget _buildNotificationIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return IconButton(
        icon: Icon(Icons.notifications_none_rounded, color: accentBlue, size: 28),
        onPressed: () {},
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          hasUnread = true;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: accentBlue, size: 28),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NotificationSheet(),
                );
              },
            ),
            if (hasUnread)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHomeDashboard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // --- CLOSEST DEADLINE REMINDER ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .where('members', arrayContains: user.email)
                .where(
                  'deadline',
                  isGreaterThan: Timestamp.now(),
                ) // Only upcoming
                .orderBy('deadline', descending: false) // Closest first
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Silently handle errors on logout
                return _buildFinalReminder("No upcoming deadlines", "All caught up!");
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildFinalReminder(
                  "No upcoming deadlines",
                  "All caught up!",
                );
              }

              final data =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              String projectName = data['name'] ?? "N/A";
              String timeDisplay = "TBD";

              if (data['deadline'] != null) {
                Timestamp ts = data['deadline'];
                DateTime deadlineDate = ts.toDate();
                int diff = deadlineDate.difference(DateTime.now()).inDays;

                if (diff == 0) {
                  timeDisplay = "DUE TODAY";
                } else if (diff == 1) {
                  timeDisplay = "DUE TOMORROW";
                } else {
                  timeDisplay = "$diff DAYS REMAINING";
                }
              }

              return _buildFinalReminder(timeDisplay, projectName);
            },
          ),

          const SizedBox(height: 50),
          Text(
            'Ongoing Projects',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Leader", "Member"].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (bool selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    selectedColor: primaryBlue,
                    labelStyle: GoogleFonts.inter(
                      color: _selectedFilter == filter ? Colors.white : primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: primaryBlue.withOpacity(0.2)),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 15),

          // --- ALL PROJECTS LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('members', arrayContains: user.email)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Suppress permission denied error during logout
                  if (snapshot.error.toString().contains("permission-denied")) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Client-side Filtering
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  if (_selectedFilter == 'All') return true;
                  
                  final data = doc.data() as Map<String, dynamic>;
                  final ownerEmail = data['ownerEmail']; // Ensure this field exists in your DB
                  final isOwner = ownerEmail == user.email;
                  
                  if (_selectedFilter == 'Leader') return isOwner;
                  if (_selectedFilter == 'Member') return !isOwner; // Member but not leader
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      "No $_selectedFilter projects found",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final project = doc.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectDetailScreen(
                              projectId: doc.id,
                              projectName: project['name'] ?? 'Untitled Group',
                            ),
                          ),
                        );
                      },
                      child: _buildProjectCard(
                        project['name'] ?? 'Untitled Group',
                        project['subject'] ?? 'General',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalReminder(String deadlineText, String projectName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'URGENT: CLOSEST DEADLINE',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deadlineText,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: $projectName',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(String title, String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromARGB(255, 229, 229, 229)),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryBlue,
                  ),
                ),
                Text(
                  subject,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 70,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No current project',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.grid_view_rounded, "Home", 0),
            _buildNavItem(Icons.assignment_rounded, "Tasks", 1),
            _buildNavItem(Icons.chat_bubble_rounded, "Chat", 2),
            _buildNavItem(Icons.person_rounded, "Profile", 3), // Updated to index 3
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    
    // Custom Icon for Chat (Index 2) to support Badge
    Widget iconWidget;
    if (index == 2) {
      iconWidget = _buildChatIconWithBadge(icon, isSelected);
    } else {
      iconWidget = Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
        size: 24,
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          if (isSelected)
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatIconWithBadge(IconData icon, bool isSelected) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
        size: 24,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      // Listen to Projects
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContains: user.email)
          .snapshots(),
      builder: (context, projectSnap) {
        if (!projectSnap.hasData) {
           return Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          );
        }
        
        return StreamBuilder<QuerySnapshot>(
          // Listen to User Meta
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('chatMeta')
              .snapshots(),
          builder: (context, metaSnap) {
            if (metaSnap.hasError) {
               // Ignore error, show icon without badge
               return Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                size: 24,
              );
            }

            int totalUnread = 0;
            if (metaSnap.hasData) {
              // Map Meta
              Map<String, int> lastSeenMap = {};
              for (var doc in metaSnap.data!.docs) {
                 lastSeenMap[doc.id] = (doc.data() as Map<String, dynamic>)['lastSeenCount'] ?? 0;
              }

              // Calc Total
              for (var pDoc in projectSnap.data!.docs) {
                final pData = pDoc.data() as Map<String, dynamic>;
                final int msgCount = pData['msgCount'] ?? 0;
                final int lastSeen = lastSeenMap[pDoc.id] ?? 0;
                if (msgCount > lastSeen) {
                  totalUnread += (msgCount - lastSeen);
                }
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 24,
                ),
                if (totalUnread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalUnread > 99 ? '99+' : '$totalUnread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
