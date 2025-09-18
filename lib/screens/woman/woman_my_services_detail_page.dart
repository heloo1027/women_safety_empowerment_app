// This page is to view service detail that are offered by me
// User can edit the offered service here and view service request from other users

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'woman_my_offer_service_page.dart';
import 'woman_my_service_requests_page.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

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
      appBar: buildStyledAppBar(
        title: "Service Details",
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
          Row(
            children: [
              Expanded(
                child: Text(
                  data['title'] ?? "No Title",
                  style: kTitleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              buildGreenChip(data['category'] ?? 'Other'),
            ],
          ),
          const SizedBox(height: 8),
          if (data['price'] != null) Text("Price: RM ${data['price']}"),
          const SizedBox(height: 8),
          Text("Description:"),
          Text(data['description'] ?? ''),
          const SizedBox(height: 8),
          if (postedDate.isNotEmpty)
            Text("Posted on: $postedDate", style: kSmallTextStyle),
          const SizedBox(height: 12),

          // View Requests Button
          Center(
            child: bigGreyButton(
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
              label: "View Service Requests",
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[400]),
          const SizedBox(height: 10),
          // Reviews
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
                          title: Text("Loading...", style: kSubtitleTextStyle),
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
          )
        ],
      ),
    );
  }
}
