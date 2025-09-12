import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'ngo_chat_page.dart';

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

  Future<void> _markAsComplete(DocumentSnapshot doc, int qty) async {
    final requestRef =
        _firestore.collection('contributions').doc(widget.requestId);

    // Update the woman's request status
    await doc.reference.update({'status': 'Completed'});

    // Increment availableQuantity of NGO request
    await requestRef.update({'availableQuantity': FieldValue.increment(-qty)});

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request marked completed")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: "Request Details"),
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
          if (requests.isEmpty) {
            return const Center(child: Text("No requests from women yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final womanId = data['womanId'] ?? '';

              return FutureBuilder<String>(
                future: _getWomanName(womanId),
                builder: (context, nameSnapshot) {
                  final womanName =
                      data['womanName'] ?? nameSnapshot.data ?? "Unknown";

                  final description = data['description'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                          Text("Quantity: ${data['quantity'] ?? 0}"),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text("Description: $description"),
                          ],
                          const SizedBox(height: 6),
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

                              // NEW: Reject button (only if status is Pending)
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
      final parentData = parentSnap.data() as Map<String, dynamic>;
      final availableQty = (parentData['availableQuantity'] ?? 0);

      if ((data['quantity'] ?? 0) > availableQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Quantity exceeds available quantity")),
        );
        return;
      }

      // Update donation status
      await doc.reference.update({'status': 'Completed'});

      // Update parent contribution's availableQuantity only
      final newAvailable = availableQty - (data['quantity'] ?? 0);
      await requestRef.update({
        'availableQuantity': newAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {}); // refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request marked completed")),
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
