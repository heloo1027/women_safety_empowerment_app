import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = "";

  // Status chip builder
  Widget buildStyledChip(String status) {
    Color bgColor;
    // Color textColor;

    switch (status) {
      case "Completed":
        bgColor = hexToColor("#a3ab94");
        // textColor = Colors.green.shade800;
        break;
      case "Rejected":
        bgColor = hexToColor("#fdaaaa");
        // textColor = Colors.red.shade800;
        break;
      default:
        bgColor = hexToColor("#e5ba9f");
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
      backgroundColor: bgColor,
    );
  }

  // ... keep your _fetchMyRequests and _showEditQuantityDialog ...

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
      appBar: buildStyledAppBar(title: "My Requests"),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by Category, Item, Status",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchMyRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      "You have no requests yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // 🔍 Apply search filter
                final filteredRequests = requests.where((data) {
                  final ngoName =
                      (data['ngoName'] ?? "").toString().toLowerCase();
                  final category =
                      (data['category'] ?? "").toString().toLowerCase();
                  final item = (data['item'] ?? "").toString().toLowerCase();
                  final status =
                      (data['status'] ?? "").toString().toLowerCase();

                  return ngoName.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      item.contains(_searchQuery) ||
                      status.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final data = filteredRequests[index];
                    final ngoId = data['ngoId'] ?? '';
                    final category = data['category'] ?? 'N/A';
                    final item = data['item'] ?? 'N/A';
                    final quantity = data['quantity']?.toString() ?? 'N/A';
                    final description = data['description'] ?? '';
                    final status = data['status'] ?? 'Pending';
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: (ngoId.toString().isNotEmpty)
                          ? _firestore
                              .collection('ngoProfiles')
                              .doc(ngoId)
                              .get()
                          : null,
                      builder: (context, ngoSnapshot) {
                        String ngoName = "Unknown NGO";

                        if (ngoSnapshot.hasData && ngoSnapshot.data!.exists) {
                          final ngoData =
                              ngoSnapshot.data!.data() as Map<String, dynamic>;
                          ngoName = ngoData['name'] ?? "Unknown NGO";
                          data['ngoName'] = ngoName; // store for search
                        }

                        return buildStyledCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NGO name + Status chip
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ngoName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  buildStyledChip(status),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildDetailRow("Category", category),
                              const SizedBox(height: 4),
                              _buildDetailRow("Item", item),
                              const SizedBox(height: 4),
                              _buildDetailRow("Quantity", quantity),

                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text("Description:",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(description,
                                      style: const TextStyle(
                                          fontSize: 14, height: 1.4)),
                                ),
                              ],

                              const SizedBox(height: 8),

                              // Requested on + buttons row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (createdAt != null)
                                    Text(
                                      "Requested on: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        // backgroundColor: hexToColor('#4a6741'),
                                        ),
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
                                    child: const Text("Chat"),
                                  ),
                                  const SizedBox(width: 8),
                                  if (status == "Pending")
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          // backgroundColor: Colors.blueAccent,
                                          ),
                                      onPressed: () {
                                        _showEditQuantityDialog(
                                          context,
                                          data['ngoId'],
                                          contributionId:
                                              data['contributionId'],
                                          requestId: data['requestId'],
                                          currentQuantity:
                                              int.tryParse(quantity) ?? 0,
                                          availableQuantity:
                                              data['availableQuantity'] ?? 0,
                                        );
                                        setState(() {}); // refresh
                                      },
                                      child: const Text("Edit Quantity"),
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
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _fetchMyRequests() {
    if (currentUser == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    final latestPerContribution = <String, List<Map<String, dynamic>>>{};
    final reqSubs = <String, StreamSubscription<QuerySnapshot>>{};
    StreamSubscription<QuerySnapshot>? contribSub;

    // listen to parent contributions collection
    contribSub = _firestore.collection('contributions').snapshots().listen(
        (contribSnap) {
      final currentContributionIds = contribSnap.docs.map((d) => d.id).toSet();

      // Ensure we have an entry for each contribution (so combined list logic is simple)
      for (final doc in contribSnap.docs) {
        final contributionId = doc.id;

        // parent fields we want to copy into each child request
        final parentData = doc.data() as Map<String, dynamic>;
        final ngoId = parentData['ngoId'];
        final category = parentData['category'];
        final item = parentData['item'];
        final availableQuantity =
            parentData['availableQuantity'] ?? parentData['quantity'] ?? 0;

        // if not subscribed yet - subscribe to child requestsFromWomen
        if (!reqSubs.containsKey(contributionId)) {
          // put an initial empty list so combined list includes other contributions immediately
          latestPerContribution[contributionId] = [];

          final sub = doc.reference
              .collection('requestsFromWomen')
              .where('womanId', isEqualTo: currentUser!.uid)
              .snapshots()
              .listen((reqSnap) {
            // map each child doc into a Map and tag with parent fields
            final list = reqSnap.docs.map((reqDoc) {
              final data = Map<String, dynamic>.from(reqDoc.data() as Map);
              data['requestId'] = reqDoc.id;
              data['contributionId'] = contributionId;
              data['ngoId'] = ngoId;
              data['category'] = category;
              data['item'] = item;
              data['availableQuantity'] = availableQuantity;
              return data;
            }).toList();

            // save latest for this contribution and emit combined flattened list
            latestPerContribution[contributionId] = list;
            final combined =
                latestPerContribution.values.expand((e) => e).toList();
            controller.add(combined);
          }, onError: (e, st) {
            controller.addError(e, st);
          });

          reqSubs[contributionId] = sub;
        } else {
          // subscription already exists — update parent info on any cached child entries
          if (latestPerContribution.containsKey(contributionId)) {
            final updated =
                latestPerContribution[contributionId]!.map((reqData) {
              reqData['ngoId'] = ngoId;
              reqData['category'] = category;
              reqData['item'] = item;
              reqData['availableQuantity'] = availableQuantity;
              return reqData;
            }).toList();
            latestPerContribution[contributionId] = updated;
          }
        }
      }

      // cancel and remove subscriptions for contributions that were removed
      final removed = reqSubs.keys
          .where((id) => !currentContributionIds.contains(id))
          .toList();
      for (final id in removed) {
        reqSubs[id]?.cancel();
        reqSubs.remove(id);
        latestPerContribution.remove(id);
      }

      // emit combined after handling adds/removes/updates
      final combined = latestPerContribution.values.expand((e) => e).toList();
      controller.add(combined);
    }, onError: (e, st) {
      controller.addError(e, st);
    });

    // cleanup when no listeners remain
    controller.onCancel = () async {
      await contribSub?.cancel();
      for (final s in reqSubs.values) {
        await s.cancel();
      }
      reqSubs.clear();
      latestPerContribution.clear();
      await controller.close();
    };

    return controller.stream;
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

  void _showEditQuantityDialog(
    BuildContext pageContext,
    String ngoId, {
    required String contributionId,
    required String requestId,
    required int currentQuantity,
    required int availableQuantity,
  }) {
    final TextEditingController controller =
        TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Update Quantity", style: kTitleTextStyle,),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Quantity",
              helperText: "Available: $availableQuantity",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              onPressed: () async {
                final newQty = int.tryParse(controller.text) ?? 0;

                // ❗ The logic to check against available quantity is now correct.
                if (newQty <= 0 || newQty > availableQuantity) {
                  // Use the 'dialogContext' from the builder for the SnackBar
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text("Invalid quantity. Max allowed: $availableQuantity"),
                      ),
                    );
                  }
                  return;
                }

                // If the quantity is valid, perform the update and show a success message
                try {
                  await _firestore
                      .collection('contributions')
                      .doc(contributionId)
                      .collection('requestsFromWomen')
                      .doc(requestId)
                      .update({'quantity': newQty});

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext); // Close the dialog first
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Quantity updated successfully!"),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text("Error updating quantity: $e"),
                      ),
                    );
                  }
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}