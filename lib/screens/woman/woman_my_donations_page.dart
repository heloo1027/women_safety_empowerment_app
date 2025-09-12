import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_chat_page.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class WomanMyRequestPage extends StatefulWidget {
  const WomanMyRequestPage({super.key});

  @override
  State<WomanMyRequestPage> createState() => _WomanMyRequestPageState();
}

class _WomanMyRequestPageState extends State<WomanMyRequestPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late final Stream<List<Map<String, dynamic>>> _myRequestsStream;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _myRequestsStream = _fetchMyDonationRequests();
  }

  // 🔹 fetch donations linked to current user
  Stream<List<Map<String, dynamic>>> _fetchMyDonationRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    final womanId = currentUser.uid;

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    final latestPerContribution = <String, List<Map<String, dynamic>>>{};
    final subs = <String, StreamSubscription<QuerySnapshot>>{};
    StreamSubscription<QuerySnapshot>? contribSub;

    contribSub =
        _firestore.collection('contributions').snapshots().listen((snap) {
      final currentIds = snap.docs.map((d) => d.id).toSet();

      for (final doc in snap.docs) {
        final contributionId = doc.id;
        final parent = doc.data() as Map<String, dynamic>;

        final ngoId = parent['ngoId'];
        final category = parent['category'];
        final item = parent['item'];
        final totalQuantity = parent['quantity'] ?? 0;
        final fulfilledQuantity = parent['fulfilledQuantity'] ?? 0;

        if (!subs.containsKey(contributionId)) {
          latestPerContribution[contributionId] = [];

          final sub = doc.reference
              .collection('donations')
              .where('womanId', isEqualTo: womanId)
              .snapshots()
              .listen((reqSnap) async {
            // ✅ fetch NGO name from ngoProfiles
            final ngoDoc =
                await _firestore.collection('ngoProfiles').doc(ngoId).get();
            final ngoName = ngoDoc.data()?['name'] ?? "Unknown NGO";

            final list = reqSnap.docs.map((donDoc) {
              final data = Map<String, dynamic>.from(donDoc.data());
              data['donationId'] = donDoc.id;
              data['contributionId'] = contributionId;
              data['ngoId'] = ngoId;
              data['ngoName'] = ngoName; // ✅ from ngoProfiles
              data['category'] = category;
              data['item'] = item;
              data['totalQuantity'] = totalQuantity;
              data['fulfilledQuantity'] = fulfilledQuantity;
              return data;
            }).toList();

            latestPerContribution[contributionId] = list;
            final combined =
                latestPerContribution.values.expand((e) => e).toList();
            controller.add(combined);
          });

          subs[contributionId] = sub;
        } else {
          if (latestPerContribution.containsKey(contributionId)) {
            final updated =
                latestPerContribution[contributionId]!.map((reqData) {
              reqData['ngoId'] = ngoId;
              reqData['category'] = category;
              reqData['item'] = item;
              reqData['totalQuantity'] = totalQuantity;
              reqData['fulfilledQuantity'] = fulfilledQuantity;
              return reqData;
            }).toList();
            latestPerContribution[contributionId] = updated;
          }
        }
      }

      // remove old subscriptions
      final removed =
          subs.keys.where((id) => !currentIds.contains(id)).toList();
      for (final id in removed) {
        subs[id]?.cancel();
        subs.remove(id);
        latestPerContribution.remove(id);
      }

      final combined = latestPerContribution.values.expand((e) => e).toList();
      controller.add(combined);
    });

    controller.onCancel = () async {
      await contribSub?.cancel();
      for (final s in subs.values) {
        await s.cancel();
      }
      subs.clear();
      latestPerContribution.clear();
      await controller.close();
    };

    return controller.stream;
  }

  // 🔹 chip widget
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
      label: Text(status,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: bgColor,
    );
  }

  // 🔹 row widget
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

  // 🔹 dialog for editing
  Future<void> _showUpdateDialog(
      BuildContext context, Map<String, dynamic> data) async {
    final ctrl = TextEditingController(text: data['quantity'].toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            "Update Quantity",
            style: kTitleTextStyle,
          ),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Quantity"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newQty = int.tryParse(ctrl.text) ?? 0;
                final totalQty = data['totalQuantity'] ?? 0;
                final fulfilled = data['fulfilledQuantity'] ?? 0;
                final maxAllowed = totalQty - fulfilled;

                if (newQty <= 0 || newQty > maxAllowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Invalid quantity. Max allowed: $maxAllowed"),
                    ),
                  );
                  return;
                }

                // Only show this SnackBar if the quantity is valid
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Quantity updated successfully"),
                  ),
                );

                await _firestore
                    .collection('contributions')
                    .doc(data['contributionId'])
                    .collection('donations')
                    .doc(data['donationId'])
                    .update({'quantity': newQty});

                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReviewDialog(
    BuildContext context, {
    required String ngoId,
    required String donationId,
    required String ngoName,
    DocumentSnapshot? existingReview,
  }) async {
    int rating = existingReview?.get('rating') ?? 0;
    final reviewController = TextEditingController(
      text: existingReview?.get('comment') ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(
                "Review for $ngoName",
                style: kTitleTextStyle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ⭐ Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Expanded(
                        child: IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() => rating = index + 1);
                          },
                        ),
                      );
                    }),
                  ),
                  Flexible(
                    child: TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: " Write your review here"),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (rating < 1 || rating > 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please provide a rating.")),
                      );
                      return;
                    }

                    final reviewData = {
                      'ngoId': ngoId,
                      'donationId': donationId,
                      'womanId': _auth.currentUser!.uid,
                      'rating': rating,
                      'comment': reviewController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    if (existingReview == null) {
                      await _firestore.collection('ngoReviews').add(reviewData);
                    } else {
                      await existingReview.reference.update(reviewData);
                    }

                    Navigator.pop(ctx);
                  },
                  child: Text(existingReview == null ? "Submit" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: ("My Donation Requests")),
      body: Column(
        children: [
          // 🔹 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by status, category, or item",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _myRequestsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading requests"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRequests = snapshot.data!;
                final requests = allRequests.where((req) {
                  final status = (req['status'] ?? "").toString().toLowerCase();
                  final category =
                      (req['category'] ?? "").toString().toLowerCase();
                  final item = (req['item'] ?? "").toString().toLowerCase();
                  return status.contains(_searchQuery) ||
                      category.contains(_searchQuery) ||
                      item.contains(_searchQuery);
                }).toList();

                if (requests.isEmpty) {
                  return const Center(child: Text("No requests found"));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final category = req['category'] ?? "N/A";
                    final item = req['item'] ?? "N/A";
                    final qty = req['quantity']?.toString() ?? "N/A";
                    final status = req['status'] ?? "Pending";
                    final description = req['description'] ?? "";
                    final createdAt =
                        (req['createdAt'] as Timestamp?)?.toDate();
                    final ngoName = req['ngoName'] ?? "Unknown NGO";

                    return buildStyledCard(
                        margin: const EdgeInsets.all(15),
                        // child: Padding(
                        //   padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 NGO + Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            const SizedBox(height: 6),

                            _buildDetailRow("Category", category),
                            _buildDetailRow("Item", item),
                            _buildDetailRow("Quantity", qty),

                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text("Description:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(description,
                                  style: const TextStyle(fontSize: 14)),
                            ],

                            if (createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Created on: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WomanChatPage(
                                          receiverId: req[
                                              'ngoId'], // ✅ pass actual ngoId
                                          receiverName:
                                              ngoName, // ✅ ngo name from ngoProfiles
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Chat"),
                                ),
                                const SizedBox(width: 8),
                                // 🔹 Review button (only if Completed)
                                if (status == "Completed")
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection('ngoReviews')
                                        .where('ngoId', isEqualTo: req['ngoId'])
                                        .where('donationId',
                                            isEqualTo: req['donationId'])
                                        .where('womanId',
                                            isEqualTo: _auth.currentUser!.uid)
                                        .limit(1)
                                        .snapshots(),
                                    builder: (context, reviewSnapshot) {
                                      if (reviewSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox.shrink();
                                      }

                                      final hasReview = reviewSnapshot
                                              .hasData &&
                                          reviewSnapshot.data!.docs.isNotEmpty;
                                      final reviewDoc = hasReview
                                          ? reviewSnapshot.data!.docs.first
                                          : null;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _showReviewDialog(
                                              context,
                                              ngoId: req['ngoId'],
                                              donationId: req[
                                                  'donationId'], // 🔹 tie to donationId
                                              ngoName: ngoName,
                                              existingReview: reviewDoc,
                                            );
                                          },
                                          child: Text(hasReview
                                              ? "Edit Review"
                                              : "Add Review"),
                                        ),
                                      );
                                    },
                                  ),
                                if (status == "Pending")
                                  ElevatedButton(
                                    onPressed: () =>
                                        _showUpdateDialog(context, req),
                                    child: const Text("Edit Quantity"),
                                  ),
                              ],
                            ),
                          ],
                        ));
                    // ),
                    // );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
