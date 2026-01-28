import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'createtask.dart';
import 'createmeeting.dart';
import 'verifymeeting.dart';
import 'review.dart';
import '../services/notification_service.dart';
import 'task.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final Color primaryBlue = const Color(0xFF1A3B5D);
  int _selectedMemberIndex = 0;

  bool _isSummaryExpanded = false;
  bool _isEditingSummary = false;
  bool _isScanning = false;

  late TextEditingController _summaryController;
  late TextEditingController _subjectController;
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController();
    _subjectController = TextEditingController();
    _statusController = TextEditingController();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _subjectController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _showProjectCode(String? code) {
    final String displayCode = code ?? "N/A";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          "Project Invite Code",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Share this 6-digit code with team members to join:",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: SelectableText(
                displayCode,
                textAlign: TextAlign.center,
                style: GoogleFonts.firaCode(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: displayCode));
              Navigator.pop(context);
              _showSnack("Invite code copied!", Colors.blue);
            },
            child: Text(
              "COPY",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: GoogleFonts.inter(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        var data = snapshot.data!.data() as Map<String, dynamic>;

        final currentUserEmail = FirebaseAuth.instance.currentUser?.email
            ?.trim()
            .toLowerCase();
        final String ownerEmail = (data['ownerEmail'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final bool isOwner = ownerEmail == currentUserEmail;

        final String inviteCode = data['inviteCode'] ?? "------";
        final String projectStatus = data['status'] ?? "Active";

        // Logic: Once Completed, the project is locked for edits.
        final bool isLocked = projectStatus == "Completed";
        final bool isFullyCompleted = projectStatus == "Completed";

        if (!_isEditingSummary) {
          _summaryController.text = data['description'] ?? "";
          _subjectController.text = data['subject'] ?? "General";
          _statusController.text = projectStatus;
        }

        List<String> members = List<String>.from(data['members'] ?? []);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(
              widget.projectName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: primaryBlue,
            elevation: 0,
            actions: [
              if (!isLocked)
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _showProjectCode(inviteCode),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFullyCompleted) _buildCompletionBanner(),
                _buildUserSpecificHeader(
                  widget.projectId,
                  currentUserEmail,
                  isOwner,
                  members,
                  isLocked,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Text(
                    "Team Progress",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
                _buildMemberSlider(members, currentUserEmail, ownerEmail),
                const SizedBox(height: 20),
                if (members.isNotEmpty && _selectedMemberIndex < members.length)
                  _buildSelectedMemberTasks(members[_selectedMemberIndex],
                      isOwner || members[_selectedMemberIndex] == currentUserEmail),
                const SizedBox(height: 30),
                _buildExpandableDetails(data, isOwner, members, isLocked),
                const SizedBox(height: 20),
                _buildBluetoothMeetingCard(isOwner, currentUserEmail, isLocked),
                const SizedBox(height: 20),
                _buildActionButtons(
                  isOwner,
                  projectStatus,
                  members,
                  data['name'],
                  currentUserEmail,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionBanner() {
    return Container(
      width: double.infinity,
      color: Colors.green.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Colors.green.shade900,
          ),
          const SizedBox(width: 8),
          Text(
            "Project Completed - History Active",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    bool isOwner,
    String status,
    List<String> members,
    String? projectName,
    String? currentUserEmail,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Owner sees "Complete" only when Active
          if (isOwner && status == "Active")
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "COMPLETE PROJECT",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () =>
                    _showCompletionDialog(context, members, projectName),
              ),
            ),

          // Everyone sees "Review" once status is "Completed"
          if (status == "Completed")
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('reviews')
                  .where('reviewerEmail', isEqualTo: currentUserEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasReviewed =
                    snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      hasReviewed ? Icons.done_all : Icons.rate_review_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      hasReviewed ? "REVIEW SUBMITTED" : "REVIEW TEAM MEMBERS",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasReviewed
                          ? Colors.grey
                          : Colors.orange.shade800,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: hasReviewed
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReviewMembersScreen(
                                  projectId: widget.projectId,
                                  members: members,
                                  projectName: projectName ?? "Project",
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showCompletionDialog(
    BuildContext context,
    List<String> members,
    String? name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Complete Project?",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will move the project to History and allow all members to review the team.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              // UPDATE: Set status to Completed immediately so it shows in History page
              await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .update({'status': 'Completed'});

              // NEW: Notify members about completion
              try {
                await NotificationService().sendNotificationToRecipients(
                  recipientEmails: members,
                  title: "Project Completed",
                  body:
                      "${name ?? 'The project'} has been marked as completed. Please submit your peer reviews.",
                  type: "project_complete",
                  projectId: widget.projectId,
                );
              } catch (e) {
                debugPrint("Error sending completion noti: $e");
              }

              _showSnack("Project Completed!", Colors.green);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDetails(
    Map<String, dynamic> data,
    bool isOwner,
    List<String> members,
    bool isLocked,
  ) {
    Timestamp? timestamp = data['deadline'] as Timestamp?;
    DateTime? deadlineDate = timestamp?.toDate();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _isSummaryExpanded = !_isSummaryExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Project Overview",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isSummaryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            _detailRow("Subject", data['subject'] ?? "General"),
            _detailRow("Status", data['status'] ?? "In Progress"),
            _detailRow(
              "Due Date",
              deadlineDate != null
                  ? "${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}"
                  : "Not Set",
            ),
            if (_isSummaryExpanded) ...[
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Summary",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOwner && !isLocked)
                    IconButton(
                      icon: Icon(
                        _isEditingSummary
                            ? Icons.check_circle
                            : Icons.edit_note,
                        color: _isEditingSummary ? Colors.green : primaryBlue,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (_isEditingSummary) {
                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(widget.projectId)
                              .update({'description': _summaryController.text});
                          setState(() => _isEditingSummary = false);
                          _showSnack("Summary Saved!", Colors.green);
                        } else {
                          setState(() => _isEditingSummary = true);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _isEditingSummary
                  ? TextField(
                      controller: _summaryController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )
                  : Text(
                      data['description'] ?? "No summary provided.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: primaryBlue.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothMeetingCard(
    bool isOwner,
    String? currentUserEmail,
    bool isLocked,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('meetings')
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasActiveMeeting =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        var meetingDoc = hasActiveMeeting ? snapshot.data!.docs.first : null;
        var meetingData = meetingDoc?.data() as Map<String, dynamic>?;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasActiveMeeting
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasActiveMeeting
                          ? Icons.bluetooth_audio_rounded
                          : Icons.bluetooth_disabled_rounded,
                      color: hasActiveMeeting
                          ? Colors.blueAccent
                          : Colors.white24,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasActiveMeeting
                              ? (meetingData?['meetingName'] ??
                                    "Active Session")
                              : "Meeting Sync",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hasActiveMeeting
                              ? "Nearby signal found"
                              : "Attendance is offline",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLocked
                      ? null
                      : () {
                          if (hasActiveMeeting) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerifyPresenceScreen(
                                  meetingId: meetingDoc!.id,
                                  projectId: widget.projectId,
                                  hostName:
                                      meetingData?['hostDeviceName'] ?? "",
                                  isHost: isOwner,
                                ),
                              ),
                            );
                          } else if (isOwner) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateMeetingScreen(
                                  projectId: widget.projectId,
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked
                        ? Colors.grey
                        : (hasActiveMeeting ? Colors.blueAccent : Colors.white),
                    foregroundColor: hasActiveMeeting
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isLocked
                        ? "PROJECT LOCKED"
                        : (hasActiveMeeting
                              ? "VERIFY ATTENDANCE"
                              : (isOwner
                                    ? "CREATE MEETING"
                                    : "WAITING FOR LEAD")),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberSlider(
    List<String> members,
    String? currentUserEmail,
    String ownerEmail,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        itemBuilder: (context, index) {
          String email = members[index];
          bool isMe = email == currentUserEmail;
          bool isLead = email == ownerEmail;
          bool isSelected = _selectedMemberIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedMemberIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMe
                      ? Colors.orangeAccent
                      : (isSelected ? primaryBlue : Colors.grey.shade200),
                  width: isMe ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? "You" : email.split('@')[0],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : primaryBlue,
                    ),
                  ),
                  Text(
                    isLead ? "Project Lead" : "Team Member",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  _buildMiniTaskBadge(
                      email, isSelected, isMe, currentUserEmail == ownerEmail),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniTaskBadge(
      String email, bool isSelected, bool isMe, bool isProjectOwner) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .where('assignedTo', isEqualTo: email)
          .snapshots(),
      builder: (context, taskSnap) {
        String taskText = "Idle";
        String? taskName;
        if (taskSnap.hasData) {
          final activeTasks = taskSnap.data!.docs
              .where((doc) => doc['status'] != 'Completed')
              .toList();
          if (activeTasks.isNotEmpty) {
            taskText = activeTasks.first['taskName'];
            taskName = taskText;
          }
        }

        bool showBeep = isProjectOwner && !isMe && taskName != null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white10 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (showBeep)
                InkWell(
                  onTap: () => _sendBeep(email, taskName!),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 14,
                      color: isSelected ? Colors.orangeAccent : Colors.orange,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.bolt_rounded,
                  size: 10,
                  color: isSelected ? Colors.orangeAccent : Colors.orange,
                ),
              if (!showBeep) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  taskText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendBeep(String targetEmail, String taskName) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showSnack("User not found", Colors.red);
        return;
      }

      final targetUid = userQuery.docs.first.id;
      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .add({
        'title': "Beep from Project Leader",
        'body': "Reminder: Please check your task '$taskName'.",
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'beep',
        'senderEmail': currentUser?.email,
        'projectId': widget.projectId,
      });

      _showSnack("Beep sent to ${targetEmail.split('@')[0]}!", Colors.green);
    } catch (e) {
      debugPrint("Error sending beep: $e");
      _showSnack("Failed to send beep", Colors.red);
    }
  }

  Widget _buildUserSpecificHeader(
    String projectId,
    String? userEmail,
    bool isOwner,
    List<String> members,
    bool isLocked,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .where('assignedTo', isEqualTo: userEmail)
          .snapshots(),
      builder: (context, taskSnapshot) {
        final pendingTasks = taskSnapshot.hasData
            ? taskSnapshot.data!.docs
                  .where((doc) => doc['status'] == 'Pending')
                  .toList()
            : [];
        bool hasMyTask = pendingTasks.isNotEmpty;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, const Color(0xFF3F6D9F)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: hasMyTask
              ? _buildTaskExistsContent(
                  pendingTasks.first['taskName'],
                  isOwner,
                  members,
                  isLocked,
                )
              : _buildNoTaskLargeContent(isOwner, members, isLocked),
        );
      },
    );
  }

  Widget _buildTaskExistsContent(
    String taskName,
    bool isOwner,
    List<String> members,
    bool isLocked,
  ) {
    return Row(
      children: [
        const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "YOUR CURRENT TASK",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                taskName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isOwner && !isLocked)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskScreen(
                  projectId: widget.projectId,
                  projectMembers: members,
                ),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildNoTaskLargeContent(
    bool isOwner,
    List<String> members,
    bool isLocked,
  ) {
    return InkWell(
      onTap: (isOwner && !isLocked)
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTaskScreen(
                  projectId: widget.projectId,
                  projectMembers: members,
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            isOwner
                ? (isLocked ? Icons.task_alt : Icons.add_task_rounded)
                : Icons.hourglass_empty_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwner ? "PROJECT STATUS" : "STATUS",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isLocked
                      ? "In Review / Finished"
                      : (isOwner
                            ? "Tap to Assign First Task"
                            : "Waiting for tasks..."),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSelectedMemberTasks(String memberEmail, bool canEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Tasks for ${memberEmail.split('@')[0]}",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: primaryBlue,
                  onPressed: () {
                    // Quick add task for this user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          projectId: widget.projectId,
                          projectMembers: [memberEmail], // Pre-filter or logic?
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('tasks')
                .where('assignedTo', isEqualTo: memberEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['status'] ?? 'Active') != 'Completed';
              }).toList();

              if (tasks.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    "No active tasks assigned.",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final taskDoc = tasks[index];
                  final taskData = taskDoc.data() as Map<String, dynamic>;
                  return TaskCard(
                    task: taskData,
                    taskRef: taskDoc.reference,
                    projectName: null, // Not needed in project view
                    primaryBlue: primaryBlue,
                    compact: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
