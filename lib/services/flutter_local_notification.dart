import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:women_safety_empowerment_app/screens/woman/notifications_page.dart';

// Initialize FlutterLocalNotificationsPlugin for showing notifications locally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Function to set up Firebase and local notifications
void setupNotifications() {
  // Android-specific initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // General initialization settings for all platforms
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // Initialize the plugin with settings and handle notification taps
  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      // Called when user taps on a notification
      if (notificationResponse.payload != null) {
        // Use the public navigatorKey here
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      }
    },
  );

  // Listen for foreground messages from Firebase Messaging
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Check if the message has notification content
    if (message.notification != null) {
      // Show the notification using local notifications plugin
      flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        message.notification!.title, // Notification title
        message.notification!.body, // Notification body
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
      );
    }
  });
}
