// This page is to view all my requested serrvices
// User can add a review to Completed service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_chat_page.dart';

class WomanRequestedServicesPage extends StatefulWidget {
  const WomanRequestedServicesPage({Key? key}) : super(key: key);

  @override
  State<WomanRequestedServicesPage> createState() =>
      _WomanRequestedServicesPageState();
}

class _WomanRequestedServicesPageState
    extends State<WomanRequestedServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Stream for service requests of current user
  Stream<List<Map<String, dynamic>>> _requestStream() async* {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      yield [];
      return;
    }

    await for (var snapshot in FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()) {
      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final serviceId = data['serviceId'];

        // Fetch service details
        final serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get();

        String serviceTitle = "Unknown Service";
        String category = "Unknown";
        String providerName = "Unknown";
        String providerId = "";

        if (serviceDoc.exists) {
          serviceTitle = serviceDoc['title'] ?? "No Title";
          category = serviceDoc['category'] ?? "Other";
          providerId = serviceDoc['userId'] ?? "";

          if (providerId.isNotEmpty) {
            final providerDoc = await FirebaseFirestore.instance
                .collection('womanProfiles')
                .doc(providerId)
                .get();
            if (providerDoc.exists) {
              providerName = providerDoc['name'] ?? "Unknown";
            }
          }
        }

        // Check if this request already has a review by current user
        final reviewSnapshot = await FirebaseFirestore.instance
            .collection('serviceReviews')
            .where('requestId', isEqualTo: doc.id)
            .where('reviewerId', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        bool hasReview = reviewSnapshot.docs.isNotEmpty;

        requests.add({
          'requestId': doc.id,
          'status': data['status'] ?? "pending",
          'requestedAt': data['requestedAt'],
          'serviceId': serviceId,
          'serviceTitle': serviceTitle,
          'category': category,
          'providerName': providerName,
          'providerId': providerId,
          'hasReview': hasReview,
        });
      }

      yield requests;
    }
  }

  Future<void> _showReviewDialog(
      BuildContext context, String serviceId, String requestId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final _commentController = TextEditingController();
    int selectedRating = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Center(
              child: Text(
                "Add Rating & Comment",
                style: kTitleTextStyle,
                textAlign: TextAlign.center,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Comment",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Submit"),
                onPressed: () async {
                  if (selectedRating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a rating.")),
                    );
                    return;
                  }

                  if (_commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a comment.")),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('serviceReviews')
                      .add({
                    'serviceId': serviceId,
                    'requestId': requestId,
                    'reviewerId': currentUser.uid,
                    'rating': selectedRating,
                    'comment': _commentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  setState(() {}); // Refresh UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review submitted.")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: buildStyledAppBar(title: "My Requested Services"),
      body: Column(
        children: [
          // Search Bar
          buildSearchBar(
            controller: _searchController,
            hintText: "Search by service or provider",
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),

          // Request List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _requestStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final requests = snapshot.data ?? [];

                // Apply search filter
                final filteredRequests = requests.where((req) {
                  final title = (req['serviceTitle'] ?? '').toLowerCase();
                  final provider = (req['providerName'] ?? '').toLowerCase();
                  return title.contains(_searchQuery) ||
                      provider.contains(_searchQuery);
                }).toList();

                if (filteredRequests.isEmpty) {
                  return const Center(
                      child: Text("No matching services found."));
                }

                return ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
                    final requestedAt =
                        (req['requestedAt'] as Timestamp?)?.toDate();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Align(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: buildWhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        req['serviceTitle'] ?? 'No Title',
                                        style: kTitleTextStyle,
                                      ),
                                    ),
                                    buildGreenChip(req['category'] ?? 'Other'),
                                  ],
                                ),
                                vSpace(4),
                                Text("Provider: ${req['providerName']}"),
                                Text("Status: ${req['status']}"),
                                vSpace(4),
                                Text(
                                  "Requested on: ${requestedAt != null ? requestedAt.toLocal().toString().split(' ')[0] : 'N/A'}",
                                  style: kSmallTextStyle,
                                ),
                                vSpace(4),
                                Row(
                                  children: [
                                    // Chat button (left)
                                    TextButton.icon(
                                      icon: Icon(Icons.chat,
                                          color: hexToColor("#a3ab94")),
                                      label: Text(
                                        "Chat",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: hexToColor("#a3ab94"),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (req['providerId'] != null &&
                                            req['providerId']
                                                .toString()
                                                .isNotEmpty &&
                                            currentUser != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => WomanChatPage(
                                                receiverId: req['providerId'],
                                                receiverName:
                                                    req['providerName'],
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Provider not available for chat."),
                                            ),
                                          );
                                        }
                                      },
                                    ),

                                    const Spacer(), // Pushes the review button to the right

                                    // Review button (right, only if completed)
                                    if (req['status'] == "completed")
                                      TextButton.icon(
                                        icon: Icon(Icons.rate_review,
                                            color: hexToColor("#a3ab94")),
                                        label: Text(
                                          req['hasReview']
                                              ? "Review Submitted"
                                              : "Add Review",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: hexToColor("#a3ab94"),
                                          ),
                                        ),
                                        onPressed: req['hasReview']
                                            ? null
                                            : () => _showReviewDialog(
                                                  context,
                                                  req['serviceId'],
                                                  req['requestId'],
                                                ),
                                      ),

                                    // Delete button if status == pending
                                    if (req['status'] == "pending")
                                      TextButton.icon(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        label: const Text("Delete",
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title:
                                                  const Text("Confirm Delete"),
                                              content: const Text(
                                                  "Are you sure you want to delete this request?"),
                                              actions: [
                                                TextButton(
                                                  child: const Text("Cancel"),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                ),
                                                TextButton(
                                                  child: const Text("Delete"),
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('serviceRequests')
                                                .doc(req['requestId'])
                                                .delete();

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Request deleted successfully.")),
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                )
                              ],
                            ),
                            margin: EdgeInsets.zero,
                          ),
                        ),
                      ),
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
}
