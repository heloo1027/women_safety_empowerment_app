// This page is to view who has requested for my service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_chat_page.dart'; // 👈 Import your chat page

class WomanServiceRequestsPage extends StatelessWidget {
  final String serviceId;
  final String serviceTitle;

  const WomanServiceRequestsPage({
    Key? key,
    required this.serviceId,
    required this.serviceTitle,
  }) : super(key: key);

  Future<String> _getRequesterName(String requesterId) async {
    final doc = await FirebaseFirestore.instance
        .collection('womanProfiles')
        .doc(requesterId)
        .get();
    if (doc.exists) {
      return doc.data()?['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  void _updateStatus(String requestId, String newStatus) {
    FirebaseFirestore.instance
        .collection('serviceRequests')
        .doc(requestId)
        .update({'status': newStatus});
  }

  void _openChat(
      BuildContext context, String requesterId, String receiverName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WomanChatPage(
          receiverId: requesterId, // the requester ID
          receiverName: receiverName, // pass the name here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: "Requests Details"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('serviceRequests')
            .where('serviceId', isEqualTo: serviceId)
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requestDocs = snapshot.data!.docs;

          if (requestDocs.isEmpty) {
            return const Center(child: Text("No requests yet."));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: requestDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final requesterId = data['requesterId'];
              final status = data['status'] ?? 'pending';

              String requestedDate = '';
              if (data['requestedAt'] != null) {
                final date = (data['requestedAt'] as Timestamp).toDate();
                requestedDate = '${date.day}/${date.month}/${date.year}';
              }

              return FutureBuilder<String>(
                future: _getRequesterName(requesterId),
                builder: (context, snapshot) {
                  final requesterName =
                      snapshot.connectionState == ConnectionState.done
                          ? snapshot.data ?? 'Unknown'
                          : 'Loading...';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      // leading:
                      //     const Icon(Icons.person, color: Colors.pinkAccent),
                      title: Text("Requester: $requesterName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("Status: "),
                              DropdownButton<String>(
                                value: data['status'], // e.g., "cancelled"
                                onChanged: (newValue) {
                                  FirebaseFirestore.instance
                                      .collection('serviceRequests')
                                      .doc(doc.id)
                                      .update({'status': newValue});
                                },
                                items: [
                                  "pending",
                                  "accepted",
                                  "completed",
                                  "cancelled",
                                ].map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          Text("Requested on: $requestedDate"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.chat, color:  Color(0xFF4a6741),),
                        onPressed: () =>
                            _openChat(context, requesterId, requesterName),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
