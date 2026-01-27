import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chatdetail.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF1A3B5D);
  String _searchText = "";

  // PRESET OPTIONS (Should closely match ChatDetail)
  final List<Color> _chatColors = [
    Colors.black87,
    const Color(0xFF1A3B5D),
    Colors.redAccent,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.indigo,
    Colors.pinkAccent,
  ];

  final List<IconData> _chatIcons = [
    Icons.tag_rounded,
    Icons.code_rounded,
    Icons.work_rounded,
    Icons.chat_bubble_rounded,
    Icons.school_rounded,
    Icons.lightbulb_rounded,
    Icons.star_rounded,
    Icons.rocket_launch_rounded,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .where('members', arrayContains: currentUser!.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState("No group chats yet");
                  }

                  // Filter projects based on search text (Client-side)
                  final allProjects = snapshot.data!.docs;
                  final filteredProjects = allProjects.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchText.toLowerCase());
                  }).toList();

                  if (filteredProjects.isEmpty) {
                    return _buildEmptyState("No chats found");
                  }

                  // LISTENER for User's Chat Meta (Last Seen Counts)
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .collection('chatMeta')
                        .snapshots(),
                    builder: (context, metaSnapshot) {
                      // Parse Meta into Map<ProjectId, lastSeenCount>
                      Map<String, int> lastSeenMap = {};
                      if (metaSnapshot.hasData) {
                        for (var doc in metaSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            lastSeenMap[doc.id] = data['lastSeenCount'] ?? 0;
                        }
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          final pData = project.data() as Map<String, dynamic>;
                          final projectId = project.id;
                          
                          // Badge Logic
                          final int msgCount = pData['msgCount'] ?? 0;
                          final int lastSeen = lastSeenMap[projectId] ?? 0;
                          final int unread = msgCount - lastSeen;

                          return _buildChatTile(projectId, pData, unread);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Signature
  Widget _buildChatTile(String projectId, Map<String, dynamic> projectData, int unreadCount) {
    // RESOLVE CUSTOM SETTINGS
    Color iconBgColor = Colors.black87;
    IconData iconData = Icons.tag_rounded;

    if (projectData.containsKey('chatColor')) {
      final int colorVal = projectData['chatColor'];
      iconBgColor = Color(colorVal);
    }

    if (projectData.containsKey('chatIcon')) {
      final int iconIndex = projectData['chatIcon'];
      if (iconIndex >= 0 && iconIndex < _chatIcons.length) {
        iconData = _chatIcons[iconIndex];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  projectId: projectId,
                  projectName: projectData['name'] ?? 'Group Chat',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Icon
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Name + Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              projectData['name'] ?? 'Untitled Group',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                          _buildLastMessageTime(projectId),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Message Preview
                      Row(
                        children: [
                          Expanded(child: _buildMessagePreview(projectId)),
                          const SizedBox(width: 8),
                          _buildUnreadBadge(unreadCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated Badge Widget
  Widget _buildUnreadBadge(int count) {
    if (count <= 0) return const SizedBox();

    final String display = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        display,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              // Edit button removed as requested
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val),
              decoration: InputDecoration(
                hintText: "Search group chat...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = "");
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview(String projectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            "No messages yet",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          );
        }

        final lastMsg = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final text = lastMsg['text'] ?? '[Image]';
        final sender = lastMsg['senderName'] ?? 'Unknown';
        
        return Text(
          "$sender: $text",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildLastMessageTime(String projectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        if (data['createdAt'] == null) return const SizedBox();

        final ts = data['createdAt'] as Timestamp;
        final dt = ts.toDate();
        final now = DateTime.now();
        
        String timeStr;
        if (now.difference(dt).inDays == 0) {
           timeStr = DateFormat('h:mm a').format(dt);
        } else if (now.difference(dt).inDays < 7) {
           timeStr = DateFormat('E').format(dt);
        } else {
           timeStr = DateFormat('MM/dd').format(dt);
        }

        return Text(
          timeStr,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
