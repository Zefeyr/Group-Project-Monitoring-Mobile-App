import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Sends a notification to a specific user.
  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String
    type, // 'invite', 'join', 'meeting', 'project_complete', 'review'
    String? projectId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'projectId': projectId, // Optional link to project
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            ...?additionalData,
          });
      debugPrint("Notification sent to $toUserId: $title");
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  /// Sends a notification to multiple users (e.g. project members).
  Future<void> sendNotificationToRecipients({
    required List<String> recipientEmails,
    required String title,
    required String body,
    required String type,
    String? projectId,
  }) async {
    for (String email in recipientEmails) {
      try {
        // Find user by email to get UID
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final uid = userQuery.docs.first.id;
          await sendNotification(
            toUserId: uid,
            title: title,
            body: body,
            type: type,
            projectId: projectId,
          );
        }
      } catch (e) {
        debugPrint("Error notifying $email: $e");
      }
    }
  }
}
