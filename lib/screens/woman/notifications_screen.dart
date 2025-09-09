import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: buildStyledAppBar(
        title: 'Notifications',
        backgroundColor: hexToColor("#dddddd"),
        textColor: hexToColor("#4a6741"),
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
              RegExp urlRegExp =
                  RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
              Match? match = urlRegExp.firstMatch(body);
              String? url = match?.group(0);

              // Remove URL from body text if needed for cleaner display
              String messageText =
                  url != null ? body.replaceAll(url, '').trim() : body;

              // Extract and format the timestamp
              Timestamp? timestamp = data['timestamp'] as Timestamp?;
              String formattedTime = '';
              if (timestamp != null) {
                DateTime dateTime = timestamp.toDate();
                formattedTime =
                    DateFormat('EEEE, MMMM d, y, h:mm a').format(dateTime);
              }

              return _buildNotificationCard(
                docId: doc.id, // pass the Firestore document ID
                title: title,
                body: messageText,
                url: url,
                formattedTime: formattedTime,
                context: context,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String docId,
    required String title,
    required String body,
    required String? url,
    required String formattedTime,
    required BuildContext context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 🔹 Title + Delete button in the same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: kTitleTextStyle.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(docId)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification deleted")),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 🔹 Body + Location inline
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black), // default text style
              children: [
                TextSpan(text: body + " "), // body content
                if (url != null)
                  TextSpan(
                    text: "location", // friendly label
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

        //  Timestamp
          Text(formattedTime, style: kSmallTextStyle),
        ]),
      ),
    );
  }
}
