import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text("My Offered Services"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WomanMyManageServicePage(
                    userId: userId,
                    serviceId: '',
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

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(data['title'] ?? "No Title"),
                  subtitle: Text(
                    "Category: ${data['category'] ?? 'Other'}\n"
                    "Price: ${data['price'] ?? 'N/A'}\n"
                    "Created: $postedDate",
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
