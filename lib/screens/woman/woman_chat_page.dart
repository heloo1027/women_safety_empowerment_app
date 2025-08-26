import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WomanChatPage extends StatefulWidget {
  final String receiverId; // 👩 The other user (woman, employer, or NGO)

  const WomanChatPage({
    Key? key,
    required this.receiverId,
  }) : super(key: key);

  @override
  _WomanChatPageState createState() => _WomanChatPageState();
}

class _WomanChatPageState extends State<WomanChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Unique chatId based on both user IDs (order-independent)
  String get chatId {
    final ids = [currentUser!.uid, widget.receiverId]..sort();
    return ids.join("_");
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final message = _messageController.text.trim();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Save message
    await chatRef.collection('messages').add({
      "senderId": currentUser!.uid,
      "receiverId": widget.receiverId,
      "message": message,
      "sentAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    // Update chat metadata
    await chatRef.set({
      "participants": [currentUser!.uid, widget.receiverId],
      "lastMessage": message,
      "lastMessageTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  /// Mark all unread messages as read
  void _markAsRead() async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("receiverId", isEqualTo: currentUser!.uid)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      doc.reference.update({"isRead": true});
    }
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
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

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
