import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Securely store user session data

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// class _RegisterScreenState extends State<RegisterScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase auth instance
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FlutterSecureStorage _secureStorage =
//       const FlutterSecureStorage(); // For secure user session storage

//   // Form key for validation
//   final _formKey = GlobalKey<FormState>();

//   // Controllers for form text fields
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   // State variables for role selection and password visibility
//   String _selectedRole = 'Woman'; // Default role
//   bool _obscurePassword = true; // Password hidden by default

//   // Toggles password visibility
//   void _togglePasswordVisibility() {
//     setState(() {
//       _obscurePassword = !_obscurePassword;
//     });
//   }

//   // Registers a new user with Firebase Authentication and saves additional data to Firestore
//   Future<void> _register() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       try {
//         // Trim the email input before use
//         String trimmedEmail = _emailController.text.trim();

//         // Check if the email is already registered
//         List<String> signInMethods =
//             await _auth.fetchSignInMethodsForEmail(trimmedEmail);

//         if (signInMethods.isNotEmpty) {
//           _showErrorDialog(
//               'This email is already registered. Please login instead.');
//           return;
//         }

//         // Create user account with Firebase Authentication
//         UserCredential userCredential =
//             await _auth.createUserWithEmailAndPassword(
//           email: trimmedEmail,
//           password: _passwordController.text,
//         );

//         User? user = userCredential.user;

//         if (user != null) {
//           // Store additional user details to Firestore
//           await _firestore.collection('users').doc(user.uid).set({
//             'userID': user.uid,
//             'email': trimmedEmail,
//             'role': _selectedRole,
//             'createdAt': FieldValue.serverTimestamp(),
//           });

//           // Store user session data securely
//           await _secureStorage.write(key: 'userID', value: user.uid);
//           await _secureStorage.write(key: 'userEmail', value: trimmedEmail);

//           // Show success dialog and navigate to login screen
//           _showSuccessDialog(
//               'Registration successful. Please login to continue.');
//         }
//       } on FirebaseAuthException catch (e) {
//         _showErrorDialog(e.message ?? 'Registration failed');
//       } catch (e) {
//         _showErrorDialog('An error occurred. Please try again.');
//         print('Registration error: $e');
//       }
//     }
//   }

//   // Shows error dialog with provided message
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Registration Failed'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Shows success dialog with provided message and navigates to login screen
//   void _showSuccessDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Success'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // Close dialog
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//               );
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // App bar with title and back button icon styling
//       appBar: AppBar(
//         title: Text(
//           "Register",
//           style: GoogleFonts.openSans(
//             fontWeight: FontWeight.bold,
//             fontSize: 18.sp,
//             color: hexToColor("#4a6741"),
//           ),
//         ),
//         centerTitle: true,
//         iconTheme: IconThemeData(
//           color: hexToColor("#4a6741"), // back icon colour
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 10.w),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 SizedBox(height: 4.h),
//                 SizedBox(height: 2.h),
//                 // Email input field
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
//                         .hasMatch(value)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 2.h),
//                 // Password input field with visibility toggle
//                 TextFormField(
//                   controller: _passwordController,
//                   decoration: InputDecoration(
//                     labelText: 'Password',
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword
//                             ? Icons.visibility
//                             : Icons.visibility_off,
//                         color: Colors.grey,
//                       ),
//                       onPressed: _togglePasswordVisibility,
//                     ),
//                   ),
//                   obscureText: _obscurePassword,
//                   validator: (value) => value == null || value.length < 6
//                       ? 'Minimum length of password is 6 characters'
//                       : null,
//                 ),
//                 SizedBox(height: 2.h),
//                 // Dropdown for selecting role
//                 DropdownButtonFormField<String>(
//                   value: _selectedRole,
//                   items: ['Woman', 'Employer', 'NGO']
//                       .map((role) =>
//                           DropdownMenuItem(value: role, child: Text(role)))
//                       .toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedRole = value!;
//                     });
//                   },
//                   decoration: const InputDecoration(labelText: 'Role'),
//                 ),
//                 const SizedBox(height: 30),
//                 // Register button
//                 ElevatedButton(
//                   onPressed: _register,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: hexToColor("#a3ab94"), // button color
//                     minimumSize: Size(double.infinity, 7.h),
//                   ),
//                   child: Text(
//                     'Register',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: hexToColor("#f5f2e9"), // button text colour
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 2.h),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // 👈 Name controller

  String _selectedRole = 'Woman';
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String trimmedEmail = _emailController.text.trim();
        String trimmedName = _nameController.text.trim();

        // Check if email already exists
        List<String> signInMethods =
            await _auth.fetchSignInMethodsForEmail(trimmedEmail);

        if (signInMethods.isNotEmpty) {
          _showErrorDialog(
              'This email is already registered. Please login instead.');
          return;
        }

        // Create Firebase Auth account
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: _passwordController.text,
        );

        User? user = userCredential.user;

        if (user != null) {
          // Save general user info
          await _firestore.collection('users').doc(user.uid).set({
            'userID': user.uid,
            'email': trimmedEmail,
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Save profile info based on role
          if (_selectedRole == 'Woman') {
            await _firestore.collection('womanProfiles').doc(user.uid).set({
              'userID': user.uid,
              'name': trimmedName,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else if (_selectedRole == 'Employer') {
            await _firestore.collection('companyProfiles').doc(user.uid).set({
              'userID': user.uid,
              'companyName': trimmedName,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else if (_selectedRole == 'NGO') {
            await _firestore.collection('ngoProfiles').doc(user.uid).set({
              'userID': user.uid,
              'name': trimmedName,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          // Save session
          await _secureStorage.write(key: 'userID', value: user.uid);
          await _secureStorage.write(key: 'userEmail', value: trimmedEmail);

          _showSuccessDialog(
              'Registration successful. Please login to continue.');
        }
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(e.message ?? 'Registration failed');
      } catch (e) {
        _showErrorDialog('An error occurred. Please try again.');
        print('Registration error: $e');
      }
    }
  }

  //  Shows error dialog with provided message
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Failed'),
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

  // Shows success dialog with provided message and navigates to login screen
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
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
        title: Text("Register",
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: hexToColor("#4a6741"),
            )),
        centerTitle: true,
        iconTheme: IconThemeData(color: hexToColor("#4a6741")),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 4.h),

                // 👇 Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: 2.h),

                // Email input
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

                // Password input
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
                  validator: (value) => value == null || value.length < 6
                      ? 'Minimum length of password is 6 characters'
                      : null,
                ),
                SizedBox(height: 2.h),

                // Role dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: ['Woman', 'Employer', 'NGO']
                      .map((role) =>
                          DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 30),

                // Register button
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hexToColor("#a3ab94"),
                    minimumSize: Size(double.infinity, 7.h),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hexToColor("#f5f2e9"),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
