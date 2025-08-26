import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'woman_requested_services_page.dart';
import 'woman_view_services_detail_page.dart';

class WomanViewServicesPage extends StatelessWidget {
  const WomanViewServicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Services"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          // 👇 My Requests Button placed on top
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WomanRequestedServicesPage()),
                  );
                },
                child: const Text(
                  "View My Requested Services",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // 👇 Service list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final serviceDocs = snapshot.data!.docs;
                if (serviceDocs.isEmpty) {
                  return const Center(
                      child: Text("No services available yet."));
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: serviceDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    String postedDate = '';
                    if (data['createdAt'] != null) {
                      final date = (data['createdAt'] as Timestamp).toDate();
                      postedDate = '${date.day}/${date.month}/${date.year}';
                    }

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Category: ${data['category'] ?? 'Other'}"),
                            if (data['price'] != null &&
                                data['price'].toString().isNotEmpty)
                              Text("Price: RM ${data['price']}"),
                            if (postedDate.isNotEmpty)
                              Text(
                                'Posted on: $postedDate',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WomanViewServicesDetailPage(
                                serviceId: doc.id,
                                serviceData: data,
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
          ),
        ],
      ),
    );
  }
}
