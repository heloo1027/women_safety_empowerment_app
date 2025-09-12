import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/screens/ngo/ngo_chat_page.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class DonationDetailsPage extends StatelessWidget {
  final String requestId;
  const DonationDetailsPage({Key? key, required this.requestId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: ("Donation Details")),
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

          if (docs.isEmpty) {
            return const Center(child: Text("No donors yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final donorData = docs[index].data() as Map<String, dynamic>;
              final donorId = donorData['womanId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('womanProfiles')
                    .doc(donorId)
                    .get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const Text("Donor: Unknown");
                  }

                  final donorProfile =
                      userSnap.data!.data() as Map<String, dynamic>?;
                  final donorName = donorProfile?['name'] ?? "Unknown";

                  return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                                      if (parentStatus == 'Completed') {
                                        return const SizedBox
                                            .shrink(); // hide buttons
                                      }

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                            // style: ElevatedButton.styleFrom(
                                            //     backgroundColor: Colors.red),
                                            icon: const Icon(Icons.close),
                                            label: const Text("Reject"),
                                          ),
                                          const SizedBox(width: 8),
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

// 🔹 custom chip builder
Widget buildStatusChip(String status) {
  Color color;
  switch (status) {
    case "Completed":
      color = hexToColor("#a3ab94");
      // textColor = Colors.green.shade800;
      break;
    case "Rejected":
      color = hexToColor("#fdaaaa");
      // textColor = Colors.red.shade800;
      break;
    default:
      color = hexToColor("#e5ba9f");
    // textColor = Colors.grey.shade800;
  }

  return Chip(
    label: Text(
      status,
      style: TextStyle(
        // color: textColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: color,
  );
}
