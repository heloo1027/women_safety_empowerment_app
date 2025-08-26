import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WomanViewServicesDetailPage extends StatelessWidget {
  final String serviceId;
  final Map<String, dynamic> serviceData;

  const WomanViewServicesDetailPage({
    Key? key,
    required this.serviceId,
    required this.serviceData,
  }) : super(key: key);

  Future<void> _requestService(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to request a service.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('service_requests').add({
        'serviceId': serviceId,
        'serviceOwnerId': serviceData['userId'],
        'requesterId': user.uid,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service request sent for: ${serviceData['title']}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String postedDate = '';
    if (serviceData['createdAt'] != null) {
      final date = (serviceData['createdAt'] as Timestamp).toDate();
      postedDate = '${date.day}/${date.month}/${date.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceData['title'] ?? "Service Detail"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: ${serviceData['title'] ?? ''}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Category: ${serviceData['category'] ?? ''}"),
            if (serviceData['price'] != null)
              Text("Price: RM ${serviceData['price']}"),
            if (postedDate.isNotEmpty) Text("Posted on: $postedDate"),
            const SizedBox(height: 12),
            Text("Description: ${serviceData['description'] ?? ''}"),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _requestService(context),
                icon: const Icon(Icons.send),
                label: const Text("Request Service"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('service_reviews')
      .where('serviceId', isEqualTo: serviceId)
      .orderBy('createdAt', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviews = snapshot.data!.docs;
    if (reviews.isEmpty) {
      return const Text("No reviews yet.");
    }

    return Column(
      children: reviews.map((reviewDoc) {
        final review = reviewDoc.data() as Map<String, dynamic>;
        final reviewerId = review['reviewerId'];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('womanProfiles') // ✅ fetch from womanProfiles
              .doc(reviewerId)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text("Loading..."),
              );
            }

            final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;

            final reviewerName = userData?['name'] ?? "Anonymous";
            final profileImage = userData?['profileImage'];

            return Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left column → Profile image
      CircleAvatar(
        radius: 24,
        backgroundImage: profileImage != null
            ? NetworkImage(profileImage)
            : null,
        child: profileImage == null ? const Icon(Icons.person) : null,
      ),

      const SizedBox(width: 12),

      // Right column → Name, rating, comment, createdAt
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + rating stars in a row
            Row(
              children: [
                Expanded(
                  child: Text(
                    reviewerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (review['rating'] != null)
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < (review['rating'] ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Comment
            Text(
              review['comment'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 4),

            // CreatedAt date
            if (review['createdAt'] != null)
              Text(
                (review['createdAt'] as Timestamp)
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0], // show date only
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    ],
  ),
);

          },
        );
      }).toList(),
    );
  },
),

          ],
        ),
      ),
    );
  }
}
