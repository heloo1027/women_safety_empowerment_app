import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/screens/ngo/ngo_chat_page.dart';

// Page to display donation details for a specific contribution request
class DonationDetailsPage extends StatelessWidget {
  final String requestId; // ID of the contribution request
  const DonationDetailsPage({Key? key, required this.requestId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: ("Donation Details")),
      // StreamBuilder listens in real-time to donations under this contribution
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contributions')
            .doc(requestId)
            .collection('donations') // subcollection for donor donations
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // Display message if no donations exist yet
          if (docs.isEmpty) {
            return const Center(child: Text("No donors yet"));
          }

          // ListView to display each donor
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final donorData = docs[index].data() as Map<String, dynamic>;
              final donorId = donorData['womanId'];

              // FutureBuilder to fetch donor's profile info
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('womanProfiles')
                    .doc(donorId)
                    .get(),
                builder: (context, userSnap) {
                  // Show spinner while loading profile
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show placeholder if donor profile does not exist
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const Text("Donor: Unknown");
                  }

                  final donorProfile =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final donorName = donorProfile?['name'] ?? "Unknown";

                  // Card to display donation info
                  return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Donor Name and Status Chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(donorName, style: kTitleTextStyle),
                                buildStatusChip(
                                  donorData['status'] ?? 'Pending',
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            const SizedBox(height: 4),

                            // Row 2: Quantity
                            Text("Quantity: ${donorData['quantity']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),

                            // Row 3: Description (if any)
                            if (donorData['description'] != null &&
                                donorData['description'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(donorData['description']),
                              ),
                            const SizedBox(height: 8),

                            // Row 4: Chat + Mark Complete buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.start,
                              children: [
                                // Always show Chat button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NGOChatPage(
                                          receiverId: donorId,
                                          receiverName: donorName,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat),
                                  label: const Text("Chat"),
                                ),

                                // Only show Reject & Complete if donor is Pending AND contribution is not Completed
                                if (donorData['status'] == 'Pending')
                                  FutureBuilder<DocumentSnapshot>(
                                    // Get parent contribution to check if it is already completed
                                    future: FirebaseFirestore.instance
                                        .collection('contributions')
                                        .doc(requestId)
                                        .get(),
                                    builder: (context, parentSnap) {
                                      if (!parentSnap.hasData)
                                        return const SizedBox.shrink();

                                      final parentData = parentSnap.data!.data()
                                              as Map<String, dynamic>? ??
                                          {};
                                      final parentStatus =
                                          parentData['status'] ?? 'In Progress';

                                      // Hide buttons if parent contribution is completed
                                      if (parentStatus == 'Completed') {
                                        return const SizedBox
                                            .shrink(); // hide buttons
                                      }

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Reject donation button
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final donationRef =
                                                  FirebaseFirestore.instance
                                                      .collection(
                                                          'contributions')
                                                      .doc(requestId)
                                                      .collection('donations')
                                                      .doc(docs[index].id);

                                              await donationRef.update(
                                                  {'status': 'Rejected'});

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Donation rejected")),
                                              );
                                            },
                                            icon: const Icon(Icons.close),
                                            label: const Text("Reject"),
                                          ),
                                          const SizedBox(width: 8),

                                          // Mark donation as completed button
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final parentRef =
                                                  FirebaseFirestore.instance
                                                      .collection(
                                                          'contributions')
                                                      .doc(requestId);

                                              final parentSnap =
                                                  await parentRef.get();
                                              final parentData =
                                                  parentSnap.data()
                                                      as Map<String, dynamic>;
                                              final totalQuantity =
                                                  parentData['quantity'] ?? 0;
                                              final currentFulfilled =
                                                  parentData[
                                                          'fulfilledQuantity'] ??
                                                      0;
                                              final donationQty =
                                                  donorData['quantity'] ?? 0;

                                              // Check if donation exceeds remaining quantity
                                              if (donationQty +
                                                      currentFulfilled >
                                                  totalQuantity) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Donation exceeds remaining quantity")),
                                                );
                                                return; // stop the flow
                                              }

                                              // Update donation status
                                              final donationRef =
                                                  FirebaseFirestore.instance
                                                      .collection(
                                                          'contributions')
                                                      .doc(requestId)
                                                      .collection('donations')
                                                      .doc(docs[index].id);

                                              await donationRef.update(
                                                  {'status': 'Completed'});

                                              // Update parent contribution
                                              final newFulfilled =
                                                  currentFulfilled +
                                                      donationQty;
                                              await parentRef.update({
                                                'fulfilledQuantity':
                                                    newFulfilled,
                                                'availableQuantity':
                                                    newFulfilled,
                                                'status': (newFulfilled ==
                                                        totalQuantity)
                                                    ? 'Completed'
                                                    : 'In Progress',
                                                'updatedAt': FieldValue
                                                    .serverTimestamp(),
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Donation approved")),
                                              );
                                            },
                                            icon: const Icon(Icons.check),
                                            label:
                                                const Text("Mark as Complete"),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Helper function to create colored status chips for donation status
Widget buildStatusChip(String status) {
  Color color;
  switch (status) {
    case "Completed":
      color = hexToColor("#a3ab94");
      break;
    case "Rejected":
      color = hexToColor("#fdaaaa");
      break;
    default:
      color = hexToColor("#e5ba9f");
  }

  return Chip(
    label: Text(
      status,
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: color,
  );
}
