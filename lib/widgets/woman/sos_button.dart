import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:geolocator/geolocator.dart'; // For location service
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/utils/utils.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isLoading = false; // Tracks loading state when sending SOS

  // Function to handle sending SOS
  Future<void> _sendSos() async {
    setState(() {
      _isLoading = true; // Start loading spinner
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // If denied, request permission
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          // If permission is still denied, show error and exit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() {
            _isLoading = false; // Stop loading spinner
          });
          return;
        }
      }

      // Get current GPS position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get current Firebase user ID
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Save SOS report to Firestore under 'sos_reports' collection
      await FirebaseFirestore.instance.collection('sos_reports').add({
        'userID': uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS sent successfully')),
      );
    } catch (e) {
      // Print error to console and show failure message
      print('SOS Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send SOS')),
      );
    }

    setState(() {
      _isLoading = false; // Stop loading spinner after process
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            // If loading, show CircularProgressIndicator
            ? const CircularProgressIndicator()
            // Else show redesigned SOS button
            : ElevatedButton(
                onPressed: _sendSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hexToColor("#ee6969"),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(50), // large circular padding
                  elevation: 10,
                  shadowColor: Colors.redAccent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 8.h, 
                      color: Colors.white,
                    ),
                    SizedBox(height: 1.h), 
                    Text(
                      'SEND SOS',
                      style: GoogleFonts.openSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp, 
                        color: Colors.white, 
                        letterSpacing: 1.2, 
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
