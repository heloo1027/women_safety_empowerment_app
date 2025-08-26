import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'woman_chat_page.dart';

class WomanRequestedServicesPage extends StatefulWidget {
  const WomanRequestedServicesPage({Key? key}) : super(key: key);

  @override
  State<WomanRequestedServicesPage> createState() => _WomanRequestedServicesPageState();
}

class _WomanRequestedServicesPageState extends State<WomanRequestedServicesPage> {


  Future<List<Map<String, dynamic>>> _fetchMyRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final requestsSnapshot = await FirebaseFirestore.instance
        .collection('service_requests')
        .where('requesterId', isEqualTo: currentUser.uid)
        .orderBy('requestedAt', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in requestsSnapshot.docs) {
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
              .collection('users')
              .doc(providerId)
              .get();
          if (providerDoc.exists) {
            providerName = providerDoc['name'] ?? "Unknown";
          }
        }
      }

      // ✅ Check if this request already has a review by current user
      final reviewSnapshot = await FirebaseFirestore.instance
          .collection('service_reviews')
          .where('requestId', isEqualTo: doc.id)
          .where('reviewerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      bool hasReview = reviewSnapshot.docs.isNotEmpty;

      results.add({
        'requestId': doc.id,
        'status': data['status'] ?? "pending",
        'requestedAt': data['requestedAt'],
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'category': category,
        'providerName': providerName,
        'providerId': providerId,
        'hasReview': hasReview, // ✅ new field
      });
    }

    return results;
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
          title: const Text("Add Rating & Comment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
// ⭐ Star rating row with reduced spacing
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
        padding: const EdgeInsets.symmetric(horizontal: 2.0), // control spacing
        child: Icon(
          index < selectedRating ? Icons.star : Icons.star_border,
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
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                if (selectedRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a rating.")),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('service_reviews')
                    .add({
                  'serviceId': serviceId,
                  'requestId': requestId,
                  'reviewerId': currentUser.uid,
                  'rating': selectedRating,
                  'comment': _commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                // ✅ Refresh page
                setState(() {});

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
      appBar: AppBar(title: const Text("My Requested Services")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyRequests(),
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
                child: Text("You haven’t requested any services yet."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final requestedAt = (req['requestedAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${req['serviceTitle']} (${req['category']})",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Provider: ${req['providerName']}"),
                      Text("Status: ${req['status']}"),
                      Text(
                        "Requested on: ${requestedAt != null ? requestedAt.toLocal().toString().split(' ')[0] : 'N/A'}",
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.blue),
                            onPressed: () {
                              if (req['providerId'] != null &&
                                  req['providerId'].toString().isNotEmpty &&
                                  currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WomanChatPage(
                                        receiverId: req['providerId']),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Provider not available for chat.")),
                                );
                              }
                            },
                          ),
                          if (req['status'] == "completed")
                            TextButton.icon(
                              icon: const Icon(Icons.rate_review,
                                  color: Colors.pinkAccent),
                              label: Text(req['hasReview']
                                  ? "Review Submitted"
                                  : "Add Review"),
                              onPressed: req['hasReview']
                                  ? null // ✅ disable button if already reviewed
                                  : () => _showReviewDialog(
                                        context,
                                        req['serviceId'],
                                        req['requestId'],
                                      ),
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
