import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ngo_chat_page.dart';

class NGOReceiveSupportPage extends StatelessWidget {
  const NGOReceiveSupportPage({Key? key}) : super(key: key);

  final List<String> statusOptions = const [
    "Pending",
    "Waiting for Collection",
    "Completed",
    "Rejected"
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Beneficiary Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('womanRequests')
            .where('ngoId',
                isEqualTo: currentUser.uid) // filter by logged-in NGO
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests yet."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final reqDoc = requests[index];
              final reqData = reqDoc.data() as Map<String, dynamic>;
              final requestId = reqDoc.id;
              final womanId = reqData["womanId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('womanProfiles')
                    .doc(womanId)
                    .get(),
                builder: (context, womanSnapshot) {
                  if (!womanSnapshot.hasData) {
                    return const SizedBox.shrink(); // empty placeholder
                  }

                  final womanData =
                      womanSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  final womanName = womanData["name"] ?? "Unknown";
                  final profileImage = womanData["profileImage"];
                  final currentStatus = reqData["status"] ?? "Pending";

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(womanName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Category: ${reqData["category"] ?? "-"}"),
                          Text("Item: ${reqData["item"] ?? "-"}"),
                          Text("Quantity: ${reqData["quantity"] ?? "-"}"),
                          Text("Description: ${reqData["description"] ?? "-"}"),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text("Status: "),
                              const SizedBox(width: 8),
                              Flexible(
                                child: DropdownButton<String>(
                                  value: currentStatus,
                                  isExpanded:
                                      true, // makes it use available width
                                  items: statusOptions
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status),
                                          ))
                                      .toList(),
                                  onChanged: (newStatus) async {
                                    if (newStatus != null) {
                                      await FirebaseFirestore.instance
                                          .collection('womanRequests')
                                          .doc(requestId)
                                          .update({"status": newStatus});
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Created: ${(reqData["createdAt"] as Timestamp?)?.toDate().toString() ?? "-"}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NGOChatPage(receiverId: womanId),
                            ),
                          );
                        },
                      ),
                    ),
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
