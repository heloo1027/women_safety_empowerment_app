// This page is to view all the service that are posted by other

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      appBar: buildStyledAppBar(title: "All Services"),
      body: Column(
        children: [
          // Search bar
          buildSearchBar(
            controller: _searchController,
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
            hintText: "Search by service or category",
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

          // Service list from Firestore
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

                final currentUser = FirebaseAuth.instance.currentUser;
                final serviceDocs = snapshot.data!.docs;

                // 🔹 Step 1: Exclude services where userId == current login user
                final otherUserServices = serviceDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['userId'] != currentUser?.uid;
                }).toList();

                // 🔹 Step 2: Apply search filter
                final filteredDocs = otherUserServices.where((doc) {
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

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Category Chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? 'No Title',
                                    style: kTitleTextStyle,
                                  ),
                                ),
                                buildGreenChip(data['category'] ?? 'Other'),
                              ],
                            ),
                            vSpace(12),
                            if (data['price'] != null &&
                                data['price'].toString().isNotEmpty)
                              Text("Price: RM ${data['price']}"),
                            vSpace(6),
                            if (postedDate.isNotEmpty)
                              Text('Posted on: $postedDate',
                                  style: kSmallTextStyle),
                          ],
                        ),
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
