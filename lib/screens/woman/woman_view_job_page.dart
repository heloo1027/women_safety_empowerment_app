import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_job_applications_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_view_job_details_page.dart';

class WomanJobScreen extends StatefulWidget {
  const WomanJobScreen({super.key});

  @override
  State<WomanJobScreen> createState() => _WomanJobScreenState();
}

class _WomanJobScreenState extends State<WomanJobScreen> {
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
      body: Column(
        children: [
          // Reusable Search Bar
          buildSearchBar(
            controller: _searchController,
            hintText: "Search by job title, type or location",
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),

          // View job applications button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: bigGreyButton(
              label: "My Job Applications",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WomanJobApplicationsPage(),
                  ),
                );
              },
            ),
          ),

          // Job List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('status', isEqualTo: 'Open')
                  .orderBy('postedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: hexToColor("#4a6741"),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No open jobs available at the moment.',
                      textAlign: TextAlign.center,
                      style: kSubtitleTextStyle,
                    ),
                  );
                }

                // Apply search filter by title, category, and location
                final jobDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  final location = (data['location'] ?? '')
                      .toString()
                      .toLowerCase(); // added

                  return title.contains(_searchQuery) ||
                      type.contains(_searchQuery) ||
                      location.contains(_searchQuery); // added
                }).toList();

                if (jobDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No jobs match your search.',
                      style: kSubtitleTextStyle,
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: jobDocs.map((doc) {
                    final data = doc.data() != null
                        ? doc.data() as Map<String, dynamic>
                        : {};

                    // Format timestamp safely
                    String postedDate = '';
                    if (data['postedAt'] != null &&
                        data['postedAt'] is Timestamp) {
                      DateTime date = (data['postedAt'] as Timestamp).toDate();
                      postedDate = '${date.day}/${date.month}/${date.year}';
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WomanViewJobScreen(jobId: doc.id),
                          ),
                        );
                      },
                      child: buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Type
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? 'No Title',
                                    style: kTitleTextStyle,
                                  ),
                                ),
                                buildGreenChip(data['type'] ?? 'N/A'),
                              ],
                            ),
                            vSpace(12),
                            // Salary
                            Row(
                              children: [
                                Icon(Icons.money_rounded,
                                    size: 20, color: hexToColor("#4a6741")),
                                vSpace(6),
                                Text(
                                  ' RM ${data['salary'] ?? 'N/A'}',
                                ),
                              ],
                            ),
                            vSpace(6),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 20, color: hexToColor("#4a6741")),
                                vSpace(6),
                                Text(
                                  ' ${data['location'] ?? 'N/A'}',
                                ),
                              ],
                            ),
                            vSpace(6),
                            // Posted Date
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
