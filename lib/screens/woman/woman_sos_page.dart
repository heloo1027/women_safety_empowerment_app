import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sizer/sizer.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/services/fcm_service.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: _sendSos,
            style: ElevatedButton.styleFrom(
              backgroundColor: hexToColor("#ee6969"),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(50),
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
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _sendSos() async {
    setState(() => _isLoading = true);

    try {
      // 1️ Check location permission
      if (!await _checkLocationPermission()) {
        setState(() => _isLoading = false);
        return;
      }

      // 2️ Get user ID & GPS position
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException("Location request timed out");
      });

      // 3️ Fetch emergency email
      String? emergencyEmail = await _getEmergencyEmail(uid);
      if (emergencyEmail == null) {
        // _showSnack('No emergency email found for this user');
        _showSnack('Please fill up an emergency email in Profile Page');
        setState(() => _isLoading = false);
        return;
      }

      // 4️ Fetch emergency contact info from users
      Map<String, dynamic>? contactInfo =
          await _getEmergencyContact(emergencyEmail);
      if (contactInfo == null) {
        _showSnack('Emergency contact not found');
        setState(() => _isLoading = false);
        return;
      }

      // 5️ Send notification
      await _notifyEmergencyContact(contactInfo, position);

      // 6 Save SOS report
      await FirebaseFirestore.instance.collection('sosReports').add({
        'userID': uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnack('SOS sent successfully');
    } catch (e) {
      print('SOS Error: $e');
      _showSnack('Failed to send SOS');
    }

    setState(() => _isLoading = false);
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _showSnack('Location permission denied');
        return false;
      }
    }
    return true;
  }

  Future<String?> _getEmergencyEmail(String uid) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('womanProfiles')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return null; // No profile document at all
    }

    // Safely read the field
    var data = doc.data() as Map<String, dynamic>?;

    if (data == null ||
        data['emergencyEmail'] == null ||
        data['emergencyEmail'].toString().trim().isEmpty) {
      return null; // Field missing or empty string
    }

    return data['emergencyEmail'].toString();
  }

  Future<Map<String, dynamic>?> _getEmergencyContact(String email) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (query.docs.isNotEmpty) {
      var doc = query.docs.first;
      var data = doc.data() as Map<String, dynamic>;

      return {
        'userID': doc.id,
        'fcmToken': data['fcmToken'], // may be null or empty
      };
    }
    return null;
  }

  Future<void> _notifyEmergencyContact(
      Map<String, dynamic> contactInfo, Position position) async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Prevent sending to yourself
    if (contactInfo['userID'] == currentUid) {
      _showSnack(
          "Emergency email is linked to your own account. Please update it in Profile Page.");
      return;
    }

    String notificationTitle = '🚨 SOS Alert: Your Friend Needs Help!';
    String notificationBody =
        'Your friend (${FirebaseAuth.instance.currentUser!.email}) is in an emergency at https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    // Always save in notifications
    await FirebaseFirestore.instance.collection('notifications').add({
      'toUserID': contactInfo['userID'],
      'title': notificationTitle,
      'body': notificationBody,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send FCM only if token exists
    if (contactInfo['fcmToken'] != null &&
        contactInfo['fcmToken'].toString().isNotEmpty) {
      await sendPushNotification(
          contactInfo['fcmToken'], notificationTitle, notificationBody);
    } else {
      // _showSnack("Emergency contact is not logged in. Push notification not sent, but saved in Notifications.");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
