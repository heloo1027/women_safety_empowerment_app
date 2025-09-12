import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_chat_page.dart';

class WomanChatListPage extends StatelessWidget {
  const WomanChatListPage({Key? key}) : super(key: key);

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
            return Center(
                child: Text(
              "No conversations yet.",
              style: kSubtitleTextStyle,
            ));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final data = chatDoc.data() as Map<String, dynamic>;

              // final participants = List<String>.from(data["participants"]);
              // final otherUserId =
              //     participants.firstWhere((id) => id != currentUser.uid);

              // final lastMessage = data["lastMessage"] ?? "";
              final participants = List<String>.from(data["participants"]);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => "",
              );

              if (otherUserId.isEmpty) {
                // No valid other participant, skip this chat
                return const SizedBox.shrink();
              }

              final lastMessage = data["lastMessage"] ?? "";

              // 🔹 Step 1: fetch role from users collection
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userRoleSnap) {
                  if (!userRoleSnap.hasData || !userRoleSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userRoleData =
                      userRoleSnap.data!.data() as Map<String, dynamic>;
                  final role = userRoleData["role"] ?? "User";

                  // 🔹 Step 2: decide which profile collection to fetch
                  late Future<DocumentSnapshot> profileFuture;
                  if (role == "Woman") {
                    profileFuture = FirebaseFirestore.instance
                        .collection("womanProfiles")
                        .doc(otherUserId)
                        .get();
                  } else if (role == "Employer") {
                    profileFuture = FirebaseFirestore.instance
                        .collection("companyProfiles")
                        .doc(otherUserId)
                        .get();
                  } else if (role == "NGO") {
                    profileFuture = FirebaseFirestore.instance
                        .collection("ngoProfiles")
                        .doc(otherUserId)
                        .get();
                  } else {
                    profileFuture = FirebaseFirestore.instance
                        .collection("users")
                        .doc(otherUserId)
                        .get();
                  }

                  // 🔹 Step 3: fetch actual profile details
                  return FutureBuilder<DocumentSnapshot>(
                    future: profileFuture,
                    builder: (context, profileSnap) {
                      String displayName = "User";
                      String? avatarUrl;

                      if (profileSnap.hasData && profileSnap.data!.exists) {
                        final profileData =
                            profileSnap.data!.data() as Map<String, dynamic>;

                        if (role == "Woman") {
                          displayName = profileData["name"] ?? "User";
                          avatarUrl = profileData["profileImage"];
                        } else if (role == "Employer") {
                          displayName =
                              profileData["companyName"] ?? "Employer";
                          avatarUrl = profileData["companyLogo"];
                        } else if (role == "NGO") {
                          displayName = profileData["name"] ?? "NGO";
                          avatarUrl = profileData["profileImage"];
                        }
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
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        onTap: () async {
                          // Mark unread as read
                          final unreadMessages = await FirebaseFirestore
                              .instance
                              .collection("chats")
                              .doc(chatDoc.id)
                              .collection("messages")
                              .where("receiverId", isEqualTo: currentUser.uid)
                              .where("isRead", isEqualTo: false)
                              .get();

                          for (var msg in unreadMessages.docs) {
                            await msg.reference.update({"isRead": true});
                          }

                          // Open Woman chat page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WomanChatPage(
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
          );
        },
      ),
    );
  }
}
