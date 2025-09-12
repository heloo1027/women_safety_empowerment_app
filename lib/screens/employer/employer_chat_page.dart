import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/services/send_message_notification.dart';
import 'package:women_safety_empowerment_app/widgets/common/chat_page_styles.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class EmployerChatPage extends StatefulWidget {
  final String applicantId;
  final String employerId;
  final String receiverName;

  const EmployerChatPage({
    Key? key,
    required this.applicantId,
    required this.employerId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _EmployerChatPageState createState() => _EmployerChatPageState();
}

class _EmployerChatPageState extends State<EmployerChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String get chatId {
    final ids = [widget.employerId, widget.applicantId]..sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      final receiverId = currentUser!.uid == widget.employerId
          ? widget.applicantId
          : widget.employerId;

      await chatRef.collection('messages').add({
        "senderId": currentUser!.uid,
        "receiverId": receiverId,
        "message": message,
        "sentAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      await chatRef.set({
        "participants": [widget.employerId, widget.applicantId],
        "lastMessage": message,
        "lastMessageTime": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final receiverDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(receiverId)
          .get();

      final receiverData = receiverDoc.data();
      String senderName = await _getSenderName();

      if (receiverDoc.exists && receiverData?['fcmToken'] != null) {
        final token = receiverData!['fcmToken'];

        await FirebaseFirestore.instance.collection('notifications').add({
          "toUserID": receiverId,
          "title": "New message from $senderName",
          "body": message,
          "timestamp": FieldValue.serverTimestamp(),
        });

        await sendMessageNotification(
          token: token,
          title: "New message from $senderName",
          body: message,
        );
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

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
      }
    }

    return senderName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(
        title: widget.receiverName,
      ),
      body: Column(
        children: [
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
                    final previousMsg = index + 1 < messages.length
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
          buildChatInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
