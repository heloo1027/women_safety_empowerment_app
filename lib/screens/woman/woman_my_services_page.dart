// This is te My Offered Services page to view all services provided by me
// Users can add a new service here

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_my_services_detail_page.dart';
import 'woman_my_offer_service_page.dart';

class WomanMyServicesPage extends StatefulWidget {
  const WomanMyServicesPage({Key? key}) : super(key: key);

  @override
  State<WomanMyServicesPage> createState() => _WomanMyServicesPageState();
}

class _WomanMyServicesPageState extends State<WomanMyServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          // 🔍 Search Bar
          buildSearchBar(
            controller: _searchController,
            hintText: "Search by title or category",
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Category
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

                            // Price
                            if (data['price'] != null &&
                                data['price'].toString().isNotEmpty)
                              Text(
                                "Price: RM ${data['price']}",
                              ),
                            vSpace(6),

                            // Location
                            // if (data['location'] != null)
                            //   Text(
                            //     "Location: ${data['location']}",
                            //     style: kSubtitleTextStyle,
                            //   ),
                            // vSpace(6),

                            // Posted Date
                            if (postedDate.isNotEmpty)
                              Text(
                                "Created on: $postedDate",
                                style: kSmallTextStyle,
                              ),
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
