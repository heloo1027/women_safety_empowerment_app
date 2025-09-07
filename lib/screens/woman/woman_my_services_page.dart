import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_my_services_detail_page.dart';
import 'woman_my_offer_service_page.dart';

class WomanMyServicesPage extends StatelessWidget {
  const WomanMyServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      appBar: buildStyledAppBar(
        title: "My Offered Services",
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WomanMyManageServicePage(
                    userId: userId,
                    serviceId: null,
                    existingData: {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final serviceDocs = snapshot.data!.docs;
          if (serviceDocs.isEmpty) {
            return const Center(
              child: Text("You haven't offered any services yet."),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: serviceDocs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              String postedDate = '';
              if (data['createdAt'] != null) {
                DateTime date = (data['createdAt'] as Timestamp).toDate();
                postedDate = '${date.day}/${date.month}/${date.year}';
              }
              return buildStyledCard(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(2), // 👈 controls inner padding
                  title: Text(
                    data['title'] ?? "No Title",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Price
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Price: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "RM ${data['price'] ?? 'N/A'}"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Category
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Category: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: data['category'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (postedDate.isNotEmpty)
                        Text(
                          "Created on: $postedDate",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WomanMyServiceDetailPage(
                          serviceId: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
