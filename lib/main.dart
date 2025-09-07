import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:women_safety_empowerment_app/authentication/auth_wrapper.dart';
import 'package:women_safety_empowerment_app/screens/woman/notifications_screen.dart'; // Import your NotificationsPage
import 'package:women_safety_empowerment_app/services/flutter_local_notification.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

// Background handler (needed for Android)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions (iOS/Android)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Save FCM token if user is logged in
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    String? token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
      });
      print('FCM Token saved: $token');
    }
  }

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notification service
  setupNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 🔹 Handle notification when app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      }
    });

    // 🔹 Handle notification when app is in background & opened
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          navigatorKey:
              _navigatorKey, // ✅ Needed to navigate outside of context
          debugShowCheckedModeBanner: false,
          title: 'Sisters',
          theme: ThemeData(
            primarySwatch: Colors.green,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.green,
            ).copyWith(
              primary: hexToColor("#4a6741"),
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF000000),
              selectionColor: Color(0xFFA3AB94),
              selectionHandleColor: Color(0xFF000000),
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)),
              ),
              labelStyle: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                ),
              ),
              hintStyle: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            textTheme: GoogleFonts.openSansTextTheme(
              Theme.of(context).textTheme,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: hexToColor("#4a6741"),
              ).copyWith(
                textStyle: MaterialStateProperty.all(
                  const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}
