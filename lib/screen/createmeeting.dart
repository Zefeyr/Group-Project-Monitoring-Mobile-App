import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CreateMeetingScreen extends StatefulWidget {
  final String projectId;

  const CreateMeetingScreen({super.key, required this.projectId});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _startMeeting() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get the local device name so members can find it
      // Note: On modern Android/iOS, this might be "iPhone" or "Pixel"
      // unless the user named it specifically.
      String localName = await FlutterBluePlus.adapterName;

      // 2. Save the meeting to Firestore
      // We store the 'localName' so the Joiner knows who to look for.
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('meetings')
          .add({
            'meetingName': _nameController.text,
            'status': 'Active',
            'startTime': FieldValue.serverTimestamp(),
            'createdAt': DateTime.now(),
            'hostDeviceName': localName, // This replaces the UUID logic
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Meeting Started! Members can now scan for you."),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Initiate Session",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A3B5D),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Session Name",
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF121212),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "START MEETING",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
