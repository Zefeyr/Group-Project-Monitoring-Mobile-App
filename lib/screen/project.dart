import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Required for Clipboard.setData
import 'createtask.dart';
import 'createmeeting.dart';
import 'verifymeeting.dart';

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

  // --- FIXED: USES THE inviteCode FIELD FROM YOUR DATABASE ---
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
        final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
        final String ownerEmail = data['ownerEmail'] ?? '';
        final bool isOwner = ownerEmail == currentUserEmail;
        final String inviteCode = data['inviteCode'] ?? "------";

        if (!_isEditingSummary) {
          _summaryController.text = data['description'] ?? "";
          _subjectController.text = data['subject'] ?? "General";
          _statusController.text = data['status'] ?? "In Progress";
        }

        List<String> members = List<String>.from(data['members'] ?? []);
        if (currentUserEmail != null && members.contains(currentUserEmail)) {
          members.remove(currentUserEmail);
          members.insert(0, currentUserEmail);
        }

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
                _buildUserSpecificHeader(
                  widget.projectId,
                  currentUserEmail,
                  isOwner,
                  members,
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
                const SizedBox(height: 30),
                _buildExpandableDetails(data, isOwner, members),
                const SizedBox(height: 20),
                _buildBluetoothMeetingCard(isOwner, currentUserEmail),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Bluetooth & UI Helper Methods Below ---

  Widget _buildBluetoothMeetingCard(bool isOwner, String? currentUserEmail) {
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
                              ? (_isScanning
                                    ? "Verifying signal..."
                                    : "Nearby signal found")
                              : "Attendance is currently offline",
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
              if (hasActiveMeeting) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.projectId)
                      .collection('meetings')
                      .doc(meetingDoc!.id)
                      .collection('attendees')
                      .snapshots(),
                  builder: (context, attendSnap) {
                    int count = attendSnap.hasData
                        ? attendSnap.data!.docs.length
                        : 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Joined Team",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "$count Members Present",
                          style: GoogleFonts.inter(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScanning
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
                    backgroundColor: hasActiveMeeting
                        ? Colors.blueAccent
                        : Colors.white,
                    foregroundColor: hasActiveMeeting
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isScanning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          hasActiveMeeting
                              ? "VERIFY PRESENCE"
                              : (isOwner
                                    ? "CREATE MEETING"
                                    : "WAITING FOR LEAD"),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
              if (isOwner && hasActiveMeeting)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(widget.projectId)
                          .collection('meetings')
                          .doc(meetingDoc!.id)
                          .update({'status': 'Finished'});
                    },
                    child: Text(
                      "END SESSION",
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                  if (isMe)
                    Text(
                      "You",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : primaryBlue,
                      ),
                    )
                  else
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: email.trim())
                          .limit(1)
                          .get(),
                      builder: (context, snapshot) {
                        String name = "";
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                          name = data['name'] ?? "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
                        }
                        
                        if (name.isEmpty) {
                           name = email.split('@')[0];
                        }
                        
                        return Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  Text(
                    isLead ? "Project Lead" : "Team Member",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  _buildMiniTaskBadge(email, isSelected),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniTaskBadge(String email, bool isSelected) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .where('assignedTo', isEqualTo: email)
          .snapshots(),
      builder: (context, taskSnap) {
        String taskText = "Idle";
        if (taskSnap.hasData) {
          final activeTasks = taskSnap.data!.docs
              .where((doc) => doc['status'] != 'Completed')
              .toList();
          if (activeTasks.isNotEmpty) taskText = activeTasks.first['taskName'];
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white10 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 10,
                color: isSelected ? Colors.orangeAccent : Colors.orange,
              ),
              const SizedBox(width: 4),
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

  Widget _buildExpandableDetails(
    Map<String, dynamic> data,
    bool isOwner,
    List<String> members,
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
                  if (isOwner)
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
                      style: GoogleFonts.inter(fontSize: 14),
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
              const SizedBox(height: 20),
              Text(
                "Team Members",
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...members.map(
                (rawEmail) {
                  final email = rawEmail.trim();
                  print("Fetching for email: '$email'"); // Debug print
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: email)
                          .limit(1)
                          .get(),
                    builder: (context, snapshot) {
                      String displayName = "";
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        print("Found user for $email: ${snapshot.data!.docs.length}"); // Debug
                        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        displayName = userData['name'] ?? 
                            "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
                      } else {
                         print("No user found for $email (snapshot has data: ${snapshot.hasData})");
                      }
                      
                      // Fallback for legacy users: Extract name from email
                      if (displayName.isEmpty) {
                        displayName = email.split('@')[0];
                      }
                      
                      return Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$email - $displayName",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
                },
              ).toList(),
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

  Widget _buildUserSpecificHeader(
    String projectId,
    String? userEmail,
    bool isOwner,
    List<String> members,
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
                )
              : _buildNoTaskLargeContent(isOwner, members),
        );
      },
    );
  }

  Widget _buildTaskExistsContent(
    String taskName,
    bool isOwner,
    List<String> members,
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
        if (isOwner)
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

  Widget _buildNoTaskLargeContent(bool isOwner, List<String> members) {
    return InkWell(
      onTap: isOwner
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
            isOwner ? Icons.add_task_rounded : Icons.hourglass_empty_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwner ? "ACTION REQUIRED" : "STATUS",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isOwner ? "Tap to Assign First Task" : "Waiting for tasks...",
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
}
