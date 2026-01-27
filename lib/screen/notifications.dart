import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Activity",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A3B5D),
                  ),
                ),
                TextButton(
                  onPressed: () => _markAllAsRead(user.uid),
                  child: Text(
                    "Mark all read",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3F6D9F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _buildEmptyState();

                // Group by Date
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Timestamp? ts = data['createdAt'] as Timestamp?;
                  if (ts == null) continue;

                  final dateKey = _getDateKey(ts.toDate());
                  if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
                  grouped[dateKey]!.add(doc);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final key = grouped.keys.elementAt(index);
                    final groupDocs = grouped[key]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Text(
                            key,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        ...groupDocs.map((doc) => _buildNotificationItem(doc, user.uid)).toList(),
                        const SizedBox(height: 10),
                      ],
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

  Widget _buildNotificationItem(QueryDocumentSnapshot doc, String uid) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isRead = data['isRead'] ?? false;
    final String type = data['type'] ?? 'system';
    final String title = data['title'] ?? 'Notification';
    final String body = data['body'] ?? '';
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    
    // Choose Icon & Color based on type
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = Colors.orange;
    Color bgColor = Colors.orange.withOpacity(0.1);

    if (type == 'project') {
      iconData = Icons.folder_rounded;
      iconColor = const Color(0xFF3F6D9F);
      bgColor = const Color(0xFF3F6D9F).withOpacity(0.1);
    } else if (type == 'invite') {
      iconData = Icons.mail_rounded;
      iconColor = Colors.purpleAccent;
      bgColor = Colors.purpleAccent.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(doc.id)
            .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
             color: isRead ? Colors.grey.shade100 : const Color(0xFF3F6D9F).withOpacity(0.2),
             width: 1,
          ),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
             )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     title,
                     style: GoogleFonts.inter(
                       fontSize: 15,
                       fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                       color: const Color(0xFF1A3B5D),
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     body,
                     style: GoogleFonts.inter(
                       fontSize: 13,
                       color: Colors.grey.shade600,
                       height: 1.4,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     _getTimeAgo(ts),
                     style: GoogleFonts.inter(
                       fontSize: 11,
                       color: Colors.grey.shade400,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: 8, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.notifications_none_rounded, size: 50, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 20),
              Text(
                 "No notifications yet",
                 style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                 ),
              ),
           ],
        ),
     );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0 && now.day == date.day) return "TODAY";
    if (diff <= 1) return "YESTERDAY";
    if (diff <= 7) return "THIS WEEK";
    return "OLDER";
  }

  String _getTimeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _markAllAsRead(String uid) async {
    final docs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
