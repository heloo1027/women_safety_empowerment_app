import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'woman_chat_page.dart'; // <-- make sure this import path is correct

class WomanMyRequestsPage extends StatefulWidget {
  const WomanMyRequestsPage({Key? key}) : super(key: key);

  @override
  _WomanMyRequestsPageState createState() => _WomanMyRequestsPageState();
}

class _WomanMyRequestsPageState extends State<WomanMyRequestsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("You must be logged in to view your requests."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('womanRequests')
            .where('womanId', isEqualTo: currentUser!.uid) // only current user
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "You have no requests yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              final category = data['category'] ?? 'N/A';
              final item = data['item'] ?? 'N/A';
              final quantity = data['quantity']?.toString() ?? 'N/A';
              final description = data['description'] ?? '';
              final status = data['status'] ?? 'Pending';
              final ngoId = data['ngoId'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.request_page, color: Colors.blue, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fetch NGO name from ngoProfiles using ngoId
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('ngoProfiles')
                                  .doc(ngoId)
                                  .get(),
                              builder: (context, ngoSnapshot) {
                                if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text("Fetching NGO...");
                                }
                                if (!ngoSnapshot.hasData || !ngoSnapshot.data!.exists) {
                                  return const Text("NGO: Unknown");
                                }
                                final ngoData = ngoSnapshot.data!.data() as Map<String, dynamic>;
                                final ngoName = ngoData['name'] ?? 'Unknown NGO';
                                return Text(
                                  "NGO: $ngoName",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text("Category: $category"),
                            Text("Item: $item"),
                            Text("Quantity: $quantity"),
                            Text("Description: $description"),
                            if (createdAt != null)
                              Text(
                                "Created at: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              "Status: $status",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == "Approved"
                                    ? Colors.green
                                    : status == "Rejected"
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (status == "Pending") // show edit button only if Pending
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditRequestPage(
                                      requestId: requests[index].id,
                                      requestData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WomanChatPage(
                                    receiverId: ngoId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Placeholder EditRequestPage
class EditRequestPage extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const EditRequestPage(
      {Key? key, required this.requestId, required this.requestData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Request")),
      body: Center(
        child: Text("Edit request for ${requestData['item']} here."),
      ),
    );
  }
}
