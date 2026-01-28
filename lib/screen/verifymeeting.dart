import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart'; // NEW
import 'package:firebase_auth/firebase_auth.dart';

class VerifyPresenceScreen extends StatefulWidget {
  final String meetingId;
  final String projectId;
  final String hostName;

  const VerifyPresenceScreen({
    super.key,
    required this.meetingId,
    required this.projectId,
    required this.hostName,
    this.isHost = false,
  });

  final bool isHost;

  @override
  State<VerifyPresenceScreen> createState() => _VerifyPresenceScreenState();
}

class _VerifyPresenceScreenState extends State<VerifyPresenceScreen> {
  bool _isScanning = false;
  String _status = "Ready to scan";

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _startAdvertising();
    }
  }

  @override
  void dispose() {
    if (widget.isHost) {
      _stopAdvertising();
    }
    super.dispose();
  }

  Future<void> _startAdvertising() async {
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: 'bf27730d-860a-4e09-889c-2d8b6a9e0fe7',
      localName: widget.hostName,
    );
    await FlutterBlePeripheral().start(advertiseData: advertiseData);
  }

  Future<void> _stopAdvertising() async {
    await FlutterBlePeripheral().stop();
  }

  Future<void> _endMeeting() async {
    try {
      await _stopAdvertising();
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('meetings')
          .doc(widget.meetingId)
          .update({'status': 'Ended'});
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error ending meeting: $e")));
    }
  }

  Future<void> _scanForHost() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      setState(() => _status = "Bluetooth is OFF!");
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Searching for ${widget.hostName}...";
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // FIX: Use advName for iOS reliability
          String foundName = r.advertisementData.advName;

          if (foundName == widget.hostName && foundName.isNotEmpty) {
            FlutterBluePlus.stopScan();
            _confirmPresence();
            break;
          }
        }
      });
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  void _confirmPresence() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('meetings')
          .doc(widget.meetingId)
          .collection('attendees')
          .doc(userEmail)
          .set({
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Present',
            'email': userEmail,
          });

      if (mounted)
        setState(() {
          _isScanning = false;
          _status = "Verified!";
        });
    } catch (e) {
      setState(() => _status = "Firestore Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Attendance")),
      body: Column(
        children: [
          // Top Section: Status & Action
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  widget.isHost ? "You are Hosting" : _status,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (widget.isHost) ...[
                  const Text(
                    "Your device is broadcasting. Keep this screen open.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _endMeeting,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text("END SESSION"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ]
                else ...[
                  if (_isScanning) const CircularProgressIndicator(),
                  if (!_isScanning && _status != "Verified!")
                    ElevatedButton(
                      onPressed: _scanForHost,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      child: const Text("Scan for Lead Device"),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Bottom Section: Attendance List
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Attendance List",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('meetings')
                .doc(widget.meetingId)
                .collection('attendees')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text("No attendees verified yet."),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final email = data['email'] ?? 'Unknown';
                  final status = data['status'] ?? 'Present';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final timeStr = timestamp != null
                      ? TimeOfDay.fromDateTime(timestamp.toDate())
                          .format(context)
                      : "-";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.check, color: Colors.green),
                    ),
                    title: Text(email.split('@')[0]), // Simple Name
                    subtitle: Text(email),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(status,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        Text(timeStr, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
