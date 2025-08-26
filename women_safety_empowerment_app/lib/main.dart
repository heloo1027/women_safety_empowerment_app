import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Core Flutter UI package
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_core/firebase_core.dart'; // Firebase initialization

import 'package:women_safety_empowerment_app/authentication/auth_wrapper.dart'; // App initial auth routing

// Main entry point of the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before running the app
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
          debugShowCheckedModeBanner: false, // Removes the debug banner on top right
          title: 'Sisters', // App title

          // Theme configuration
          theme: ThemeData(
            primarySwatch: Colors.green, // Default primary colour swatch for app

            // Global text selection theme (cursor and selection highlight colours)
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Color(0xFF000000),
              selectionColor: Color(0xFFA3AB94),
              selectionHandleColor: Color(0xFF000000),
            ),

            // Global InputDecorationTheme for TextFormFields/TextFields
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)), // Black underline when focused
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)), // Black underline when enabled but not focused
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
          ),
          // The first screen loaded 
          // AuthWrapper decides whether to show login, register, or home based on auth state
          home: const AuthWrapper(),
        );
      },
    );
  }
}
