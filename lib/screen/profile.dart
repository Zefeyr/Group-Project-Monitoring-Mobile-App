import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryBlue = const Color(0xFF1A3B5D);
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedTab = 0; // 0: Work History, 1: Peer Reviews

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("Please log in"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(currentUser!.uid),
            const SizedBox(height: 20),
            _buildStatsSection(currentUser!.email),
            const SizedBox(height: 20),

            _buildTabToggle(),
            const SizedBox(height: 20),
            _selectedTab == 0
                ? _buildWorkHistoryList(currentUser!.email)
                : _buildPeerReviewsList(currentUser!.email),
            // Tab Toggle for Work & Reviews
            _buildTabToggle(),
            const SizedBox(height: 20),
            _selectedTab == 0
                ? _buildProjectHistoryList(currentUser!.email)
                : _buildPeerReviewsList(currentUser!.email),
            const SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectHistoryList(String? email) {
    if (email == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('reviewedBy', arrayContains: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _emptyState("No completed projects yet."),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String name = data['name'] ?? "Project";
            String subject = data['subject'] ?? "General";
            Timestamp? deadline = data['deadline'];
            String dateStr = deadline != null
                ? DateFormat('MMM d, y').format(deadline.toDate())
                : "";

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Text(
                          dateStr.isNotEmpty
                              ? "$subject • Due $dateStr"
                              : subject,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200);

        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = userData['name'] ?? currentUser?.displayName ?? "Student";
        String matric = userData['matric_no'] ?? "No ID";
        String major = userData['major'] ?? "General";
        String email = userData['email'] ?? currentUser?.email ?? "";
        String photoUrl = userData['photo_url'] ?? "";
        String status = userData['status'] ?? "Available";
        String kulliyyah = userData['kulliyyah'] ?? "Kulliyyah";
        String semester = userData['semester'] ?? "1";
        String skills = userData['skills'] ?? "N/A";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(userData: userData),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    color: primaryBlue,
                    tooltip: "Edit Profile",
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(
                  0,
                  -20,
                ), // Slight nudge up to overlap the empty space left by the button row
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.1),
                              width: 3,
                            ),
                            image: photoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade300,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: status == "Available"
                                  ? Colors.green
                                  : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tagChip(matric, Colors.blue.shade50, primaryBlue),
                        _tagChip(major, Colors.purple.shade50, Colors.purple),
                        _tagChip(
                          kulliyyah,
                          Colors.orange.shade50,
                          Colors.deepOrange,
                        ),
                        _tagChip(
                          "Sem $semester",
                          Colors.teal.shade50,
                          Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (userData['bio'] != null && userData['bio'].isNotEmpty)
                      Text(
                        userData['bio'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (skills != "N/A")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                skills,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tagChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildStatsSection(String? email) {
    if (email == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContains: email)
          .snapshots(),
      builder: (context, projectSnapshot) {
        int totalProjects = 0;
        int completed = 0;

        if (projectSnapshot.hasData) {
          totalProjects = projectSnapshot.data!.docs.length;
          // Count projects where this user has submitted a review (is in 'reviewedBy')
          completed = projectSnapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final reviewedBy = List<String>.from(data['reviewedBy'] ?? []);
            return reviewedBy.contains(email);
          }).length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('reviews_data')
              .where('targetUser', isEqualTo: email)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            String ratingStr = "N/A";

            if (reviewSnapshot.hasData &&
                reviewSnapshot.data!.docs.isNotEmpty) {
              final docs = reviewSnapshot.data!.docs;
              double totalRating = 0;
              for (var doc in docs) {
                totalRating += (doc['rating'] as num).toDouble();
              }
              double avg = totalRating / docs.length;
              ratingStr = avg.toStringAsFixed(1);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _statCard(
                    "Projects",
                    "$totalProjects",
                    Icons.folder_open_rounded,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    "Completed",
                    "$completed",
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    "Avg Rating",
                    ratingStr,
                    Icons.star_rounded,
                    color: Colors.amber,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    Color color = const Color(0xFF1A3B5D),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton("Work History", 0)),
          Expanded(child: _tabButton("Peer Reviews", 1)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 13,
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHistoryList(String? email) {
    if (email == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('tasks')
          .where('assignedTo', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No work history found yet.");
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            String status = data['status'] ?? 'Pending';
            Color statusColor = status == 'Completed'
                ? Colors.green
                : Colors.orange;
            if (status == 'Pending') statusColor = Colors.blue;

            String dateStr = "";
            if (data['createdAt'] != null) {
              DateTime dt = (data['createdAt'] as Timestamp).toDate();
              dateStr = DateFormat('MMM d, y').format(dt);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['taskName'] ?? "Untitled Task",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Text(
                          "Submitted: $dateStr",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeerReviewsList(String? email) {
    if (email == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      // Using collectionGroup to find reviews across all projects
      stream: FirebaseFirestore.instance
          .collectionGroup('reviews_data')
          .where('targetUser', isEqualTo: email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("PeerReview Error: ${snapshot.error}");
          return _emptyState("Could not load reviews.");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No peer reviews received yet.");
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            double rating = (data['rating'] ?? 0).toDouble();
            String comment = data['comment'] ?? "No comment";
            String projectName = data['projectName'] ?? "Peer Review";

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F6D9F), Color(0xFF1A3B5D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          projectName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: i < rating ? Colors.amber : Colors.white30,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\"$comment\"",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Verified Teammate",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF69F0AE), // Light Green accent
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          style: GoogleFonts.inter(color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
