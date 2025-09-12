import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'employer_chat_page.dart'; // import your EmployerChatPage

class EmployerChatListPage extends StatelessWidget {
  const EmployerChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    final employerId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Conversations"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .snapshots(), // 🔹 Listen to all chats
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No conversations yet."));
          }

          // 🔹 Filter chats that include this employerId
          final chatDocs = snapshot.data!.docs.where((doc) {
            final chatId = doc.id;
            return chatId.contains(employerId);
          }).toList();

          if (chatDocs.isEmpty) {
            return const Center(child: Text("No conversations found."));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatId = chatDoc.id;

              // 🔹 Extract applicantId (the other person in chatId)
              final ids = chatId.split("_");
              ids.remove(employerId);
              final applicantId = ids.isNotEmpty ? ids.first : "unknown";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('womanProfiles') // applicant profiles
                    .doc(applicantId)
                    .get(),
                builder: (context, userSnapshot) {
                  String applicantName = "Applicant";
                  String? profileImage;

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    applicantName = data['name'] ?? "Applicant";
                    profileImage = data['profileImage'];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          (profileImage != null && profileImage.isNotEmpty)
                              ? NetworkImage(profileImage)
                              : null,
                      child: (profileImage == null || profileImage.isEmpty)
                          ? Text(applicantName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(applicantName),
                    subtitle: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .orderBy('sentAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, msgSnapshot) {
                        if (msgSnapshot.hasData &&
                            msgSnapshot.data!.docs.isNotEmpty) {
                          final lastMsg =
                              msgSnapshot.data!.docs.first['message'] ?? "";
                          return Text(lastMsg,
                              maxLines: 1, overflow: TextOverflow.ellipsis);
                        }
                        return const Text("No messages yet");
                      },
                    ),
                    trailing: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatId)
                          .collection("messages")
                          .where("receiverId",
                              isEqualTo: employerId) // msgs sent to employer
                          .where("isRead", isEqualTo: false)
                          .snapshots(),
                      builder: (context, unreadSnap) {
                        if (unreadSnap.hasData &&
                            unreadSnap.data!.docs.isNotEmpty) {
                          final count = unreadSnap.data!.docs.length;
                          return CircleAvatar(
                            radius: 12,
                            backgroundColor: hexToColor("#a3ab94"),
                            child: Text(
                              "$count",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    onTap: () async {
                      // ✅ Mark unread as read for employer
                      final unreadMessages = await FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatId)
                          .collection("messages")
                          .where("receiverId", isEqualTo: employerId)
                          .where("isRead", isEqualTo: false)
                          .get();

                      for (var msg in unreadMessages.docs) {
                        msg.reference.update({"isRead": true});
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployerChatPage(
                            applicantId: applicantId,
                            employerId: employerId,
                            receiverName: applicantName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
