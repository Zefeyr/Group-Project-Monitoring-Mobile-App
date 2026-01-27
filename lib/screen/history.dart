import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project.dart'; // Ensure this matches your project detail file name

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final Color primaryBlue = const Color(0xFF1A3B5D);

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Project History",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query logic: Fetch only projects where the user is a member AND status is Completed
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where('members', arrayContains: userEmail)
            .where('status', isEqualTo: 'Completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No completed projects yet.",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String projectId = docs[index].id;
              String projectName = data['name'] ?? "Untitled Project";
              String subject = data['subject'] ?? "General";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.green.shade700,
                    ),
                  ),
                  title: Text(
                    projectName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  subtitle: Text(
                    "Subject: $subject",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(
                          projectId: projectId,
                          projectName: projectName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
