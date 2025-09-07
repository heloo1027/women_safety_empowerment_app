import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_requested_services_page.dart';
import 'woman_view_services_detail_page.dart';

class WomanViewServicesPage extends StatefulWidget {
  const WomanViewServicesPage({Key? key}) : super(key: key);

  @override
  State<WomanViewServicesPage> createState() => _WomanViewServicesPageState();
}

class _WomanViewServicesPageState extends State<WomanViewServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(
        title: "All Services",
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: buildSearchBar(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
              hintText: "Search services...",
            ),
          ),

          // 📌 My Requests Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: bigGreyButton(
              label: "View My Requested Services",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WomanRequestedServicesPage(),
                  ),
                );
              },
            ),
          ),

          // 📋 Service list from Firestore
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

                // Apply search filter
                final filteredDocs = serviceDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category =
                      (data['category'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No matching services found."),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    String postedDate = '';
                    if (data['createdAt'] != null) {
                      final date = (data['createdAt'] as Timestamp).toDate();
                      postedDate = '${date.day}/${date.month}/${date.year}';
                    }

                    return buildStyledCard(
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
