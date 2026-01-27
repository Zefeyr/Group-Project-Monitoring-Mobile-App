import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String
  targetUid; // The UID of the person being reviewed (we'll need to fetch this from email if not available directly)
  final String
  targetEmail; // Fallback or primary identifier if UID isn't passed directly
  final String targetName; // For display

  const SubmitReviewScreen({
    super.key,
    required this.targetUid, // We might need to resolve email->uid first if project.dart only has emails
    required this.targetEmail,
    required this.targetName,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short comment.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // If targetUid is empty or invalid, we need to handle it.
      // Assuming caller resolves email to UID or passes correct UID.
      // For now, we'll write to users/{targetUid}/reviews

      // NOTE: If in project.dart we only have email, we need to ensure we pass the correct UID.
      // If we don't have UID, we'd need to query it. I'll implement a resolution step if needed,
      // but ideally we passed the correct UID.

      String targetUid = widget.targetUid;

      // Logic to fallback to email query if UID is missing could go here,
      // but let's assume we get a valid UID for now to keep it clean.

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('reviews')
          .add({
            'reviewerUid': user.uid,
            'reviewerName': user.displayName ?? 'Team Member',
            'rating': _rating,
            'comment': _commentController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Review Team Member',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A3B5D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3B5D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFECF2FF),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Color(0xFF1A3B5D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "How was working with?",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.targetName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A3B5D),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Rate Performance",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => _rating = index + 1.0),
                        icon: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write your feedback here...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3B5D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Submit Review",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
