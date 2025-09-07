import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

// -------------------- Colors --------------------
const Color bubbleMeColor = Color(0xFFA3AB94);
const Color bubbleOtherColor = Color(0xFFDDDDDD);
const Color dateSeparatorColor = Colors.grey;


// -------------------- Chat Input --------------------
Widget buildChatInput({
  required TextEditingController controller,
  required VoidCallback onSend,
}) {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.openSans(fontSize: 14),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    ),
  );
}

// -------------------- Message Bubble --------------------
Widget buildMessageBubble({
  required String message,
  required bool isMe,
  Timestamp? sentAt,
}) {
  String formattedTime = '';
  if (sentAt != null) {
    final date = sentAt.toDate();
    formattedTime = DateFormat.Hm().format(date);
  }

  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      constraints: BoxConstraints(
        maxWidth: 0.7 *
            MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                .size
                .width,
      ),
      decoration: BoxDecoration(
        color: isMe ? bubbleMeColor : bubbleOtherColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style:
                GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (formattedTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                formattedTime,
                style: GoogleFonts.openSans(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// -------------------- Date Separator --------------------
Widget buildDateSeparator(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.openSans(
          fontSize: 12,
          color: dateSeparatorColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// -------------------- Time Formatter --------------------
String formatDateSeparator(Timestamp timestamp) {
  final date = timestamp.toDate();
  final now = DateTime.now();

  // Only compare year/month/day
  final dateOnly = DateTime(date.year, date.month, date.day);
  final nowOnly = DateTime(now.year, now.month, now.day);

  final diff = nowOnly.difference(dateOnly).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('dd/MM/yyyy').format(date);
}

// -------------------- Build Message List Item --------------------
Widget buildMessageListItem({
  required DocumentSnapshot msg,
  required bool isMe,
  DocumentSnapshot? previousMsg,
}) {
  final Timestamp? sentAt = msg['sentAt'];
  bool showDateSeparator = false;
  String separatorText = '';

  if (sentAt != null) {
    if (previousMsg == null || previousMsg['sentAt'] == null) {
      showDateSeparator = true;
    } else {
      final prevDate = previousMsg['sentAt'].toDate();
      final currDate = sentAt.toDate();
      if (prevDate.day != currDate.day ||
          prevDate.month != currDate.month ||
          prevDate.year != currDate.year) {
        showDateSeparator = true;
      }
    }

    if (showDateSeparator) {
      separatorText = formatDateSeparator(sentAt);
    }
  }

  return Column(
    children: [
      if (showDateSeparator) buildDateSeparator(separatorText),
      buildMessageBubble(
        message: msg['message'],
        isMe: isMe,
        sentAt: sentAt,
      ),
    ],
  );
}
