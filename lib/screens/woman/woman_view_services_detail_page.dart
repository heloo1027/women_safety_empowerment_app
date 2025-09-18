// This page is to view service detail that are offered by other users
// User can request for service here

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

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
        const SnackBar(
            content: Text("You must be logged in to request a service.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('serviceRequests').add({
        'serviceId': serviceId,
        'serviceOwnerId': serviceData['userId'],
        'requesterId': user.uid,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Service request sent for: ${serviceData['title']}")),
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
      appBar: buildStyledAppBar(title: "Service Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // push items to edges
              children: [
                Expanded(
                  child: Text(
                    "${serviceData['title'] ?? ''}",
                    style: kTitleTextStyle,
                    overflow: TextOverflow.ellipsis, // prevents overflow
                  ),
                ),
                buildGreenChip(serviceData['category'] ?? 'Other'),
              ],
            ),
            const SizedBox(height: 8),
            if (serviceData['price'] != null)
              Text("Price: RM ${serviceData['price']}"),
            const SizedBox(height: 8),
            Text("Description:"),
            Text(serviceData['description'] ?? ''),
            const SizedBox(height: 8),
            if (postedDate.isNotEmpty)
              Text("Posted on: $postedDate", style: kSmallTextStyle),
            const SizedBox(height: 12),
            Center(
              child: bigGreyButton(
                onPressed: () => _requestService(context),
                label: "Request Service",
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              "Reviews",
              style: kTitleTextStyle,
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('serviceReviews')
                  .where('serviceId', isEqualTo: serviceId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;
                if (reviews.isEmpty) {
                  return Text("No reviews yet.", style: kSubtitleTextStyle);
                }

                return Column(
                  children: reviews.map((reviewDoc) {
                    final review = reviewDoc.data() as Map<String, dynamic>;
                    final reviewerId = review['reviewerId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('womanProfiles')
                          .doc(reviewerId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title:
                                Text("Loading...", style: kSubtitleTextStyle),
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
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: profileImage != null
                                    ? NetworkImage(profileImage)
                                    : null,
                                child: profileImage == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            reviewerName,
                                            style: kSubtitleTextStyle.copyWith(
                                              fontWeight: FontWeight.bold,
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
                                    Text(
                                      review['comment'] ?? '',
                                      style: kSubtitleTextStyle,
                                    ),
                                    const SizedBox(height: 4),
                                    if (review['createdAt'] != null)
                                      Text(
                                        (review['createdAt'] as Timestamp)
                                            .toDate()
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                        style: kSmallTextStyle,
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
