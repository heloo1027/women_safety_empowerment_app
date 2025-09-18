import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Core Flutter UI package
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:page_transition/page_transition.dart'; // Animated page transitions
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Securely store user session data


import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/auth_wrapper.dart';
import 'package:women_safety_empowerment_app/authentication/forgot_password.dart';
import 'package:women_safety_empowerment_app/authentication/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase auth instance
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(); // For secure user session storage

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Toggles the visibility of the password field
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        User? user = userCredential.user; // Retrieves signed-in user

        if (user != null) {
          // Save user ID and email securely in device storage
          await _secureStorage.write(key: 'userID', value: user.uid);
          await _secureStorage.write(key: 'userEmail', value: user.email!);

          // Retrieve and save FCM token
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          String? token = await messaging.getToken();

          if (token != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'fcmToken': token,
            });
            print('FCM Token saved after login: $token');
          }

          if (mounted) {
            // Navigate to AuthWrapper after successful login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(e.message ?? 'Login failed');
      } catch (e) {
        _showErrorDialog('An error occurred. Please try again.');
        print('Login error: $e');
      }
    }
  }

  // Shows a pop-up alert dialog displaying login errors
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Text(
                  "Login",
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: hexToColor("#4a6741"),
                  ),
                ),
                SizedBox(height: 4.h),
                // Email input field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                // Password input field with visibility toggle
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your password'
                      : null,
                ),
                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                          child: const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.openSans(
                        color: hexToColor("#4a6741"),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                // Login button
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hexToColor("#a3ab94"), // button color
                    minimumSize: Size(double.infinity, 7.h),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: hexToColor("#f5f2e9"), //button text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                // Register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            duration: const Duration(milliseconds: 300),
                            child: const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Register here",
                        style: GoogleFonts.openSans(
                          color: hexToColor("#4a6741"),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
