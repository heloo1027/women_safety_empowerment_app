import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/screens/ngo/ngo_home_screen.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_home_screen.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_home_screen.dart';

// This widget decides which screen to show based on authentication and user role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to authentication state changes in real time
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If still checking authentication state, show loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

          // If user is logged in (snapshot has data)
        } else if (snapshot.hasData) {
          // Fetch user's role from Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              // Show loading while fetching user document
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );

                // Handle error or missing data
              } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: Text('Error loading user data')),
                );
              }

              // If data is retrieved successfully, extract it as Map
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'] ?? ''; // Get user role

              // Navigate to the respective home screen based on role
              if (role == 'Woman') {
                return const WomanHomeScreen();
              } else if (role == 'Employer') {
                return const EmployerHomeScreen();
              } else if (role == 'NGO') {
                return const NGOHomeScreen();
              } else {
                // return const Scaffold(
                //   body: Center(child: Text('Unknown role')),
                // );
                return const LoginScreen();
              }
            },
          );

          // If user is not logged in, show login screen
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
