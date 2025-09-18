import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/services/send_message_notification.dart';
import 'package:women_safety_empowerment_app/widgets/common/chat_page_styles.dart';

// Chat page for Woman user to chat with another user
class WomanChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const WomanChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _WomanChatPageState createState() => _WomanChatPageState();
}

class _WomanChatPageState extends State<WomanChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Unique chat ID based on both participants' IDs (sorted to be consistent)
  String get chatId {
    final ids = [currentUser!.uid, widget.receiverId]..sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _markAsRead(); // Mark unread messages as read on page load
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Marks all unread messages in this chat as read
  Future<void> _markAsRead() async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .where("receiverId", isEqualTo: currentUser!.uid)
          .where("isRead", isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({"isRead": true});
      }
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  // Handles pressing the send button
  void _handleSendButton() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return; // Do nothing if input is empty

    _messageController.clear();
    _sendMessage(message); // Send message
  }

  // Sends a message to Firestore and triggers notification
  Future<void> _sendMessage(String message) async {
    try {
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      // Add message to messages subcollection
      await chatRef.collection('messages').add({
        "senderId": currentUser!.uid,
        "receiverId": widget.receiverId,
        "message": message,
        "sentAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      // Update chat info (last message, participants)
      await chatRef.set({
        "participants": [currentUser!.uid, widget.receiverId],
        "lastMessage": message,
        "lastMessageTime": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Push notification logic (same as original)
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      final receiverData = receiverDoc.data();
      String senderName = await _getSenderName(); // Get sender's display name

      if (receiverDoc.exists && receiverData?['fcmToken'] != null) {
        final token = receiverData!['fcmToken'];

        // Save notification in Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          "toUserID": widget.receiverId,
          "title": "New message from $senderName",
          "body": message,
          "timestamp": FieldValue.serverTimestamp(),
        });

        // Send push notification
        await sendMessageNotification(
          token: token,
          title: "New message from $senderName",
          body: message,
        );
      }
    } catch (e) {
      // Show error if sending fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending message: $e")),
      );
    }

    _messageController.clear();
  }

  // Fetches the display name of the current user based on role
  Future<String> _getSenderName() async {
    String senderName = "Someone";
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final senderData = senderDoc.data();

    if (senderData != null && senderData.containsKey('role')) {
      final role = senderData['role'];

      if (role == 'Woman') {
        final womanDoc = await FirebaseFirestore.instance
            .collection('womanProfiles')
            .doc(currentUser!.uid)
            .get();
        final womanData = womanDoc.data();
        if (womanData != null && womanData.containsKey('name')) {
          senderName = womanData['name'];
        }
      } else if (role == 'Employer') {
        final companyDoc = await FirebaseFirestore.instance
            .collection('companyProfiles')
            .doc(currentUser!.uid)
            .get();
        final companyData = companyDoc.data();
        if (companyData != null && companyData.containsKey('companyName')) {
          senderName = companyData['companyName'];
        }
      } else if (role == 'NGO') {
        final ngoDoc = await FirebaseFirestore.instance
            .collection('ngoProfiles')
            .doc(currentUser!.uid)
            .get();
        final ngoData = ngoDoc.data();
        if (ngoData != null && ngoData.containsKey('name')) {
          senderName = ngoData['name'];
        }
      }
    }

    return senderName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjust when keyboard appears
      appBar: buildStyledAppBar(
        title: widget.receiverName, // Display receiver's name
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;
                    final previousMsg = index < messages.length - 1
                        ? messages[index + 1]
                        : null;

                    return buildMessageListItem(
                      msg: msg,
                      isMe: isMe,
                      previousMsg: previousMsg,
                    );
                  },
                );
              },
            ),
          ),

          // Chat input
          buildChatInput(
            controller: _messageController,
            onSend: _handleSendButton,
          ),
        ],
      ),
    );
  }
}
