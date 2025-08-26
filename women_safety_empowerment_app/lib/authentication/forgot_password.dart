import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/utils/utils.dart';

// Stateful widget for Forgot Password functionality
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();

  // Function to send password reset email
  Future<void> _sendResetEmail() async {
    String email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showDialog('Please enter your email');
      return;
    }

    try {
      // Check if email exists in Firestore 'users' collection
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        _showDialog('No user found with this email');
        return;
      }

      // If user exists, send password reset email via Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessDialog(
          'A password reset email has been sent. Please check your email.');
    } on FirebaseAuthException catch (e) {
      _showDialog(e.message ?? 'Failed to send reset email');
    } catch (e) {
      _showDialog('An error occurred. Please try again.');
      debugPrint('Password reset error: $e');
    }
  }

  // Shows a simple dialog with a message
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Shows a success dialog and pops back to login screen
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to login page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: hexToColor("#4a6741"),
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: hexToColor("#4a6741"), // back icon colour
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Enter your email to receive a password reset link.',
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 30),
            Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey, // highlighted text background
                ),
                colorScheme: Theme.of(context)
                    .colorScheme
                    .copyWith(primary: Colors.black),
              ),
              child: TextField(
                controller: _emailController,
                cursorColor: Colors.black, // changes blinking cursor color
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: hexToColor("#a3ab94"), // button color
                minimumSize: Size(double.infinity, 7.h),
              ),
              child: Text(
                'Send Reset Email',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hexToColor("#f5f2e9"), //button text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
