import 'ngo_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

// Page to display all requests submitted by women for a specific NGO donation
class RequestDetailsPage extends StatefulWidget {
  final String requestId; // the NGO request document ID

  const RequestDetailsPage({Key? key, required this.requestId})
      : super(key: key);

  @override
  State<RequestDetailsPage> createState() =>
      _NGOCompletedRequestDetailsPageState();
}

class _NGOCompletedRequestDetailsPageState extends State<RequestDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the name of a woman from Firestore using her user ID
  Future<String> _getWomanName(String womanId) async {
    try {
      final doc =
          await _firestore.collection('womanProfiles').doc(womanId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? "Unknown";
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: "Request Details"),
      // Listen to real-time updates for requests from women under this NGO contribution
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contributions')
            .doc(widget.requestId)
            .collection('requestsFromWomen')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          // Show message if there are no requests
          if (requests.isEmpty) {
            return const Center(child: Text("No requests from women yet."));
          }

          // List all requests
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final womanId = data['womanId'] ?? '';

              // Fetch woman's name asynchronously if not already stored in the request
              return FutureBuilder<String>(
                future: _getWomanName(womanId),
                builder: (context, nameSnapshot) {
                  final womanName =
                      data['womanName'] ?? nameSnapshot.data ?? "Unknown";

                  final description = data['description'] ?? '';

                  // Card for each request
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Woman's name
                              Expanded(
                                child: Text(
                                  womanName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              buildStatusChip(data['status'] ?? 'Pending'),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Quantity requested
                          Text("Quantity: ${data['quantity'] ?? 0}"),

                          // Optional description
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text("Description: $description"),
                          ],
                          const SizedBox(height: 6),

                          // Buttons for interaction
                          Wrap(
                            children: [
                              // Chat button (always available)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NGOChatPage(
                                        receiverId: womanId,
                                        receiverName: womanName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat),
                                label: const Text("Chat"),
                              ),
                              const SizedBox(width: 8),

                              // Reject button (only if status is Pending)
                              if ((data['status'] ?? '') == 'Pending')
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await doc.reference
                                        .update({'status': 'Rejected'});
                                    setState(
                                        () {}); // refresh to hide the button
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Request rejected")),
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text("Reject"),
                                ),
                              if ((data['status'] ?? '') == 'Pending')
                                const SizedBox(width: 8),

                              // Mark as Completed button (only if Pending)
                              if ((data['status'] ?? '') == 'Pending')
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final requestRef = _firestore
                                        .collection('contributions')
                                        .doc(widget.requestId);
                                    final parentSnap = await requestRef.get();
                                    final parentData = parentSnap.data()
                                        as Map<String, dynamic>;
                                    final availableQty =
                                        (parentData['availableQuantity'] ?? 0);

                                    if ((data['quantity'] ?? 0) >
                                        availableQty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Quantity exceeds available quantity")),
                                      );
                                      return;
                                    }

                                    // Update donation status
                                    await doc.reference
                                        .update({'status': 'Completed'});

                                    // Update parent contribution's availableQuantity only
                                    final newAvailable =
                                        availableQty - (data['quantity'] ?? 0);
                                    await requestRef.update({
                                      'availableQuantity': newAvailable,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });

                                    setState(() {}); // refresh UI
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Request marked completed")),
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text("Mark as Completed"),
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
          );
        },
      ),
    );
  }
}

// custom chip builder
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
