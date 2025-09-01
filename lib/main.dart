import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Core Flutter UI package
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_core/firebase_core.dart'; // Firebase initialization
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user check

import 'package:women_safety_empowerment_app/authentication/auth_wrapper.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart'; // App initial auth routing

// Main entry point of the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before running the app

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions
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

  runApp(const MyApp()); // Launch the app
}

// The root widget of this app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Sizer for responsive UI
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner:
              false, // Removes the debug banner on top right
          title: 'Sisters', // App title

          // Theme configuration
          theme: ThemeData(
            primarySwatch:
                Colors.green, // Default primary colour swatch for app
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch:
                  Colors.green, // Use the green swatch to derive the scheme
            ).copyWith(
              primary: hexToColor("#4a6741"), // Set a specific primary color
            ),

            // Global text selection theme (cursor and selection highlight colours)
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF000000),
              selectionColor: Color(0xFFA3AB94),
              selectionHandleColor: Color(0xFF000000),
            ),

            // Global InputDecorationTheme for TextFormFields/TextFields
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Color(0xFF000000)), // Black underline when focused
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Color(
                        0xFF000000)), // Black underline when enabled but not focused
              ),
              labelStyle: GoogleFonts.lato(
                // use Lato for labels
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                ),
              ),
              hintStyle: GoogleFonts.lato(
                // use Lato for hints if any
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ),

            // Default TextTheme using Open Sans for all general text in the app
            textTheme: GoogleFonts.openSansTextTheme(
              Theme.of(context).textTheme,
            ),

            // This theme will be applied to all TextButtons
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: hexToColor("#4a6741"),
              ).copyWith(
                // The text style, including fontWeight, is part of the button's overall theme
                textStyle: MaterialStateProperty.all(
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // The first screen loaded
          // AuthWrapper decides whether to show login, register, or home based on auth state
          home: const AuthWrapper(),
        );
      },
    );
  }
}
