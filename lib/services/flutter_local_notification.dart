import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:women_safety_empowerment_app/screens/woman/notifications_screen.dart';
import 'package:women_safety_empowerment_app/main.dart'; 

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
  //     // if (notificationResponse.payload != null) {
  //       // You can pass data in the payload to determine the destination.
  //       // For example, if you include a 'screen' key in your payload.
  //       // navigatorKey.currentState?.pushNamed(notificationResponse.payload!);
  //       if (notificationResponse.payload != null) {
  //       _navigatorKey.currentState?.push(
  //         MaterialPageRoute(builder: (_) => const NotificationsPage()),
  //       );
  //     }
  //   },
  // );

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      if (notificationResponse.payload != null) {
        // Use the public navigatorKey here
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      }
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
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
