import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'ngo_chat_page.dart';

class NGOChatListPage extends StatelessWidget {
  const NGOChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: currentUser.uid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return const Center(child: Text("No conversations yet."));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final data = chatDoc.data() as Map<String, dynamic>;

              // Get the other participant
              final participants = List<String>.from(data["participants"]);
              final otherUserId =
                  participants.firstWhere((id) => id != currentUser.uid);

              final lastMessage = data["lastMessage"] ?? "";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("womanProfiles") // ✅ Chat is with women
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  String displayName = "User";
                  String? avatarUrl;

                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>;
                    displayName = userData["name"] ?? "User";
                    avatarUrl = userData["profileImage"];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(displayName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatDoc.id)
                          .collection("messages")
                          .where("receiverId", isEqualTo: currentUser.uid)
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
                      // ✅ Mark unread as read
                      final unreadMessages = await FirebaseFirestore.instance
                          .collection("chats")
                          .doc(chatDoc.id)
                          .collection("messages")
                          .where("receiverId", isEqualTo: currentUser.uid)
                          .where("isRead", isEqualTo: false)
                          .get();

                      for (var msg in unreadMessages.docs) {
                        msg.reference.update({"isRead": true});
                      }

                      // ✅ Open NGO chat page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NGOChatPage(
                            receiverId: otherUserId,
                            receiverName: displayName,
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
