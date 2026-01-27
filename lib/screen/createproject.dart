import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  DateTime? _selectedDate;
  final List<String> _invitedEmails = [];
  bool _isLinkEnabled = false;
  bool _isLoading = false;
  final Color primaryBlue = const Color(0xFF1A3B5D);

  // --- LOGIC: JOIN BY CODE ---
  Future<void> _joinProjectByCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('projects')
          .where('inviteCode', isEqualTo: code.toUpperCase().trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnackBar("Invalid code. Please check again.");
      } else {
        final projectDoc = query.docs.first;
        await projectDoc.reference.update({
          'members': FieldValue.arrayUnion([user.email]),
          'pendingInvitations': FieldValue.arrayRemove([user.email]),
        });
        // 2. Notify Project Owner
        try {
          // Verify owner email to send noti
          String ownerEmail = projectDoc['ownerEmail'];

          await NotificationService().sendNotificationToRecipients(
            recipientEmails: [ownerEmail],
            title: "New Member Joined",
            body:
                "${user.email} joined ${projectDoc['name']} using the invite code.",
            type: "invite", // or 'join'
            projectId: projectDoc.id,
          );
        } catch (e) {
          debugPrint("Failed to notify owner: $e");
        }

        _showSnackBar("Welcome to ${projectDoc['name']}!");
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Error joining: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Join Code', style: GoogleFonts.outfit()),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "e.g. XJ92LK"),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinProjectByCode(codeController.text);
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: GENERATE & CREATE ---
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(math.Random().nextInt(chars.length)),
      ),
    );
  }

  void _addEmail() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty &&
        email.contains('@') &&
        !_invitedEmails.contains(email)) {
      setState(() {
        _invitedEmails.add(email);
        _emailController.clear();
      });
    }
  }

  Future<void> _createProject() async {
    if (_nameController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _selectedDate == null) {
      _showSnackBar('Please complete all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final inviteCode = _isLinkEnabled ? _generateInviteCode() : null;

      await FirebaseFirestore.instance.collection('projects').add({
        'name': _nameController.text.trim(),
        'subject': _subjectController.text.trim(),
        'deadline': Timestamp.fromDate(_selectedDate!),
        'userId': user?.uid,
        'ownerEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Active',
        'inviteCode': inviteCode,
        'members': [user?.email],
        'pendingInvitations': _invitedEmails,
        'isPublicJoinEnabled': _isLinkEnabled,
      });

      // 4. Create Notification for the Creator
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('notifications')
          .add({
            'title': 'Project Created',
            'body':
                'You have successfully created "${_nameController.text.trim()}".',
            'type': 'project',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 5. Send Invite Notifications
      for (String email in _invitedEmails) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final invitedUserId = userQuery.docs.first.id;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(invitedUserId)
              .collection('notifications')
              .add({
                'title': 'Project Invitation',
                'body':
                    'You have been invited to join "${_nameController.text.trim()}".',
                'type': 'invite',
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: Text(
          'Launch Project',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryBlue,
      ),
      // --- ADDED A "JOIN" BUTTON FOR QUICK ACCESS ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showJoinDialog,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        icon: const Icon(Icons.vpn_key_rounded),
        label: const Text("Have a code?"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionLabel("PROJECT IDENTITY"),
            _buildCardField(
              _nameController,
              "Project Name",
              Icons.rocket_launch_rounded,
            ),
            const SizedBox(height: 16),
            _buildCardField(
              _subjectController,
              "Subject / Course",
              Icons.auto_stories_rounded,
            ),
            const SizedBox(height: 30),
            _buildSectionLabel("TIMELINE"),
            _buildDatePicker(),
            const SizedBox(height: 30),
            _buildSectionLabel("COLLABORATION"),
            _buildJoinLinkToggle(),
            const SizedBox(height: 16),
            _buildEmailInviteField(),
            _buildInviteChips(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS (Unchanged from your snippet but kept for completeness) ---

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildCardField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    ),
  );

  Widget _buildDatePicker() => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030),
      );
      if (picked != null) setState(() => _selectedDate = picked);
    },
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedDate != null
              ? primaryBlue.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: primaryBlue),
          const SizedBox(width: 15),
          Text(
            _selectedDate == null
                ? "Select Submission Deadline"
                : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate!),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: _selectedDate == null ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildJoinLinkToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _isLinkEnabled ? primaryBlue.withOpacity(0.03) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _isLinkEnabled ? primaryBlue : Colors.grey.shade200,
      ),
    ),
    child: SwitchListTile(
      title: Text(
        "Invite via Join Code",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: const Text(
        "Generates a unique code for your team",
        style: TextStyle(fontSize: 12),
      ),
      value: _isLinkEnabled,
      activeColor: primaryBlue,
      onChanged: (val) => setState(() => _isLinkEnabled = val),
    ),
  );

  Widget _buildEmailInviteField() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: "Enter teammate's email",
        prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
        suffixIcon: IconButton(
          icon: Icon(Icons.add_circle, color: primaryBlue),
          onPressed: _addEmail,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
      onSubmitted: (_) => _addEmail(),
    ),
  );

  Widget _buildInviteChips() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Wrap(
      spacing: 8,
      children: _invitedEmails
          .map(
            (email) => Chip(
              label: Text(
                email,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onDeleted: () => setState(() => _invitedEmails.remove(email)),
              backgroundColor: primaryBlue.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 65,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _createProject,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: primaryBlue.withOpacity(0.4),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              "CREATE PROJECT",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    ),
  );

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
