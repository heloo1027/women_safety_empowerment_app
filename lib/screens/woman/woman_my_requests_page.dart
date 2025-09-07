import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

import 'woman_chat_page.dart';

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

    Widget _buildDetailRow(String label, String value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: buildStyledAppBar(title: "My Requests"), // ✅ reuse appbar
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('womanRequests')
            .where('womanId', isEqualTo: currentUser!.uid)
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

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ngoProfiles')
                    .doc(ngoId)
                    .get(),
                builder: (context, ngoSnapshot) {
                  String ngoName = "Unknown NGO";
                  if (ngoSnapshot.hasData && ngoSnapshot.data!.exists) {
                    final ngoData =
                        ngoSnapshot.data!.data() as Map<String, dynamic>;
                    ngoName = ngoData['name'] ?? "Unknown NGO";
                  }

                  return buildStyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NGO name + Status in one row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ngoName,
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == "Approved"
                                    ? Colors.green.shade100
                                    : status == "Rejected"
                                        ? Colors.red.shade100
                                        : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: status == "Approved"
                                      ? Colors.green
                                      : status == "Rejected"
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Category / Item / Quantity
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow("Category", category),
                            const SizedBox(height: 4),
                            _buildDetailRow("Item", item),
                            const SizedBox(height: 4),
                            _buildDetailRow("Quantity", quantity),
                          ],
                        ),

                        // Description block
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Description:",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              description,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),

                        // Requested on + Chat button in same row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (createdAt != null)
                              Text(
                                "Requested on: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            IconButton(
                              icon: Icon(Icons.chat,
                                  color: hexToColor('#4a6741')),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WomanChatPage(
                                      receiverId: ngoId,
                                      receiverName: ngoName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
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
