import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
  });

  @override
  State<VerifyPresenceScreen> createState() => _VerifyPresenceScreenState();
}

class _VerifyPresenceScreenState extends State<VerifyPresenceScreen> {
  bool _isScanning = false;
  String _status = "Ready to scan";

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_isScanning) const CircularProgressIndicator(),
            if (!_isScanning && _status != "Verified!")
              ElevatedButton(
                onPressed: _scanForHost,
                child: const Text("Scan for Lead Device"),
              ),
          ],
        ),
      ),
    );
  }
}
