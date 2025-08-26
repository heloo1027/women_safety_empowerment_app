import 'package:sizer/sizer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: hexToColor("#4a6741"),
          ),
        ),
        backgroundColor: hexToColor("#dddddd"),
        iconTheme: IconThemeData(
          color: hexToColor("#4a6741"),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserID', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String body = data['body'] ?? 'No content';
              String title = data['title'] ?? 'No Title';

              // Extract URL from body
              RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
              Match? match = urlRegExp.firstMatch(body);
              String? url = match?.group(0);

              // Remove URL from body text if needed for cleaner display
              String messageText = url != null ? body.replaceAll(url, '').trim() : body;

              return Card(
                color: hexToColor("#f5f2e9"),
                margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Body text with clickable URL inline
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.8.h),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.openSans(
                              fontSize: 11.sp,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: messageText + ' '),
                              if (url != null)
                                TextSpan(
                                  text: 'location',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      Uri uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not launch $url')),
                                        );
                                      }
                                    },
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Timestamp with top padding
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h),
                        child: Text(
                          data['timestamp'] != null
                              ? (data['timestamp'] as Timestamp).toDate().toString()
                              : '',
                          style: GoogleFonts.openSans(
                            fontSize: 10.sp,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
