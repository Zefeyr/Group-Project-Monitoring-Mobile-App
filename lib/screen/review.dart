import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewMembersScreen extends StatefulWidget {
  final String projectId;
  final List<String> members;
  final String projectName;

  const ReviewMembersScreen({
    super.key,
    required this.projectId,
    required this.members,
    required this.projectName,
  });

  @override
  State<ReviewMembersScreen> createState() => _ReviewMembersScreenState();
}

class _ReviewMembersScreenState extends State<ReviewMembersScreen> {
  final Color primaryBlue = const Color(0xFF1A3B5D);

  // Storing ratings and comments for each member in a Map
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    // Initialize data for all members except "Me"
    for (var email in widget.members) {
      if (email != currentUserEmail) {
        _ratings[email] = 5.0;
        _controllers[email] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final otherMembers = widget.members
        .where((m) => m != currentUserEmail)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Team Review",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: otherMembers.length,
              itemBuilder: (context, index) {
                final email = otherMembers[index];
                return _buildMemberReviewCard(email);
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildMemberReviewCard(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "Rating: ${_ratings[email]!.round()}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _ratings[email]!,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _ratings[email] = val),
                ),
              ),
            ],
          ),
          TextField(
            controller: _controllers[email],
            decoration: InputDecoration(
              hintText: "Feedback for ${email.split('@')[0]}...",
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: _submitAllReviews,
          child: Text(
            "SUBMIT ALL REVIEWS",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAllReviews() async {
    try {
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Loop through each reviewed member and prepare Firestore entry
      for (var email in _ratings.keys) {
        final reviewRef = FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('reviews_data') // Detailed review data
            .doc();

        batch.set(reviewRef, {
          'reviewer': currentUserEmail,
          'targetUser': email,
          'rating': _ratings[email],
          'comment': _controllers[email]?.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 2. Mark THIS user as "Finished Reviewing" in a subcollection
      final userDoneRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('reviews') // This collection tracks WHO has finished
          .doc(currentUserEmail);

      batch.set(userDoneRef, {
        'reviewerEmail': currentUserEmail,
        'done': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // 3. LOGICAL GATE: Check if the project is fully complete
      await _checkAndCompleteProject();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reviews submitted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkAndCompleteProject() async {
    final reviewsSnap = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('reviews')
        .get();

    // If total reviews submitted matches total member count, move to History
    if (reviewsSnap.docs.length >= widget.members.length) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({'status': 'Completed'});
    }
  }
}
