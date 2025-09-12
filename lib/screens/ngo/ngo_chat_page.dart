import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/services/send_message_notification.dart';
import 'package:women_safety_empowerment_app/widgets/common/chat_page_styles.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class NGOChatPage extends StatefulWidget {
  final String receiverId; // Woman's userId
  final String receiverName; // Woman's name

  const NGOChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _NGOChatPageState createState() => _NGOChatPageState();
}

class _NGOChatPageState extends State<NGOChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String get chatId {
    final ids = [currentUser!.uid, widget.receiverId]..sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  // void _markAsRead() async {
  //   final unreadMessages = await FirebaseFirestore.instance
  //       .collection("chats")
  //       .doc(chatId)
  //       .collection("messages")
  //       .where("receiverId", isEqualTo: currentUser!.uid)
  //       .where("isRead", isEqualTo: false)
  //       .get();

  //   for (var doc in unreadMessages.docs) {
  //     doc.reference.update({"isRead": true});
  //   }
  // }

  // Future<void> _sendMessage() async {
  //   final text = _messageController.text.trim();
  //   if (text.isEmpty) return;

  //   final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  //   await chatRef.collection('messages').add({
  //     "senderId": currentUser!.uid,
  //     "receiverId": widget.receiverId,
  //     "message": text,
  //     "sentAt": FieldValue.serverTimestamp(),
  //     "isRead": false,
  //   });

  //   await chatRef.set({
  //     "participants": [currentUser!.uid, widget.receiverId],
  //     "lastMessage": text,
  //     "lastMessageTime": FieldValue.serverTimestamp(),
  //   }, SetOptions(merge: true));

  //   _messageController.clear();

  //   // Scroll to bottom
  //   _scrollController.animateTo(
  //     0,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );

  //   // TODO: Trigger notification to woman (FCM)
  // }

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

      final receiverId = widget.receiverId; // Woman

      // Save message in Firestore
      await chatRef.collection('messages').add({
        "senderId": currentUser!.uid, // NGO
        "receiverId": receiverId,
        "message": message,
        "sentAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });

      // Update chat metadata
      await chatRef.set({
        "participants": [currentUser!.uid, receiverId],
        "lastMessage": message,
        "lastMessageTime": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send notification if woman has FCM token
      final receiverDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(receiverId)
          .get();

      final receiverData = receiverDoc.data();
      String senderName = await _getSenderName();

      if (receiverDoc.exists && receiverData?['fcmToken'] != null) {
        final token = receiverData!['fcmToken'];

        // Save notification in Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          "toUserID": receiverId,
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
      debugPrint("Error sending message: $e");
    }
  }

  Future<String> _getSenderName() async {
    String senderName = "NGO";
    final ngoDoc = await FirebaseFirestore.instance
        .collection('ngoProfiles')
        .doc(currentUser!.uid)
        .get();
    final ngoData = ngoDoc.data();
    if (ngoData != null && ngoData.containsKey('name')) {
      senderName = ngoData['name'];
    }
    return senderName;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Chat with ${widget.receiverName}", style: kapp,),
      // ),
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
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final previousMsg = index + 1 < messages.length
                        ? messages[index + 1]
                        : null;
                    final isMe = msg['senderId'] == currentUser!.uid;

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
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
