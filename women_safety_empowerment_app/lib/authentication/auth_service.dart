// import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication

// // AuthService class handles all authentication-related logic
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Register a user with email and password
//   Future<User?> registerWithEmailPassword(String email, String password) async {
//     try {
//       // Call Firebase's createUserWithEmailAndPassword function
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return result.user; // Return the User object if successful
//       // If registration fails, print error message and return null
//     } on FirebaseAuthException catch (e) {
//       print('Register error: ${e.message}');
//       return null;
//     }
//   }

//   // Login a user with email and password
//   Future<User?> loginWithEmailPassword(String email, String password) async {
//     try {
//       // Call Firebase's signInWithEmailAndPassword function
//       UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return result.user; // Return the User object if successful
//     } on FirebaseAuthException catch (e) {
//       // If login fails, print error message and return null
//       print('Login error: ${e.message}');
//       return null;
//     }
//   }

//   // Sign out the current user
//   Future<void> signOut() async {
//     await _auth.signOut(); // Call Firebase's signOut function to log out user
//   }
// }
