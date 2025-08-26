import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'woman_my_offer_service_page.dart';
import 'woman_my_service_requests_page.dart';

class WomanMyServiceDetailPage extends StatelessWidget {
  final String serviceId;
  final Map<String, dynamic> data;

  const WomanMyServiceDetailPage({
    Key? key,
    required this.serviceId,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    String postedDate = '';
    if (data['createdAt'] != null) {
      final date = (data['createdAt'] as Timestamp).toDate();
      postedDate = '${date.day}/${date.month}/${date.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? "Service Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WomanMyManageServicePage(
                    userId: currentUser.uid,
                    serviceId: serviceId,
                    existingData: data,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            data['title'] ?? "No Title",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("Category: ${data['category'] ?? 'Other'}"),
          Text("Price: ${data['price'] ?? 'N/A'}"),
          Text("Posted on: $postedDate"),
          const SizedBox(height: 12),
          Text(
            "Description:\n${data['description'] ?? 'No description provided'}",
            style: const TextStyle(fontSize: 14),
          ),

          const Divider(height: 32, thickness: 1),

          // 🔹 View Requests Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WomanServiceRequestsPage(
                    serviceId: serviceId,
                    serviceTitle: data['title'] ?? 'Service',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
            label: const Text("View Requests"),
          ),

          const Divider(height: 32, thickness: 1),

          // 🔹 Ratings & Comments Section
          const Text(
            "Ratings & Comments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('service_ratings')
                .where('serviceId', isEqualTo: serviceId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ratingDocs = snapshot.data!.docs;
              if (ratingDocs.isEmpty) {
                return const Text("No ratings or comments yet.");
              }
              return Column(
                children: ratingDocs.map((doc) {
                  final rData = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text("Rating: ${rData['rating'] ?? 'N/A'}"),
                    subtitle: Text(rData['comment'] ?? ''),
                    trailing: Text(
                      (rData['createdAt'] as Timestamp?) != null
                          ? (rData['createdAt'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0]
                          : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }
}
