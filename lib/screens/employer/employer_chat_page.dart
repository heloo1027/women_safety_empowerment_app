import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmployerChatPage extends StatefulWidget {
  final String applicantId;
  final String employerId;

  const EmployerChatPage({
    Key? key,
    required this.applicantId,
    required this.employerId,
  }) : super(key: key);

  @override
  _EmployerChatPageState createState() => _EmployerChatPageState();
}

class _EmployerChatPageState extends State<EmployerChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// 🔹 Generate consistent chatId (sorted so both parties use the same id)
  String get chatId {
    final ids = [widget.employerId, widget.applicantId]..sort();
    return ids.join("_");
  }

  /// 🔹 Send message + update chat metadata
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // Save message
    await chatRef.collection('messages').add({
      "senderId": currentUser!.uid,
      "receiverId": widget.applicantId,
      "message": message,
      "sentAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    // 🔹 Update chat metadata (participants + lastMessage)
    await chatRef.set({
      "participants": {
        "employerId": widget.employerId,
        "applicantId": widget.applicantId,
      },
      "lastMessage": message,
      "lastMessageTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  // Mark as read function
  void _markAsRead() async {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final unreadMessages = await FirebaseFirestore.instance
      .collection("chats")
      .doc(chatId)
      .collection("messages")
      .where("receiverId", isEqualTo: currentUser.uid)
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
          // 🔹 Chat messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
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

          // 🔹 Input field
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
