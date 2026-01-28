import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Local Notification Setup (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If notification is available, show it locally using flutter_local_notifications
      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  Future<void> saveFcmToken(String uid) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint("FCM Token saved: $token");
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  Future<void> deleteToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint("FCM Token deleted for ${user.uid}");
      }
    } catch (e) {
      debugPrint("Error deleting FCM token: $e");
    }
  }

  /// Sends a notification to a specific user (Writes to Firestore for History & Badge)
  /// AND the backend Cloud Function will pick this up to send the actual Push Notification.
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
      debugPrint("Notification doc created for $toUserId: $title");
    } catch (e) {
      debugPrint("Error sending notification doc: $e");
    }
  }

  /// Sends a notification to multiple users.
  Future<void> sendNotificationToRecipients({
    required List<String> recipientEmails,
    required String title,
    required String body,
    required String type,
    String? projectId,
  }) async {
    for (String email in recipientEmails) {
      try {
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

