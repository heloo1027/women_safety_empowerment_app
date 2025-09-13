import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_view_job_details_page.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

class WomanJobApplicationsPage extends StatefulWidget {
  const WomanJobApplicationsPage({super.key});

  @override
  State<WomanJobApplicationsPage> createState() =>
      _WomanJobApplicationsPageState();
}

class _WomanJobApplicationsPageState extends State<WomanJobApplicationsPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: buildStyledAppBar(title: "My Job Applications"),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by job title or status",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔹 Jobs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: hexToColor("#4a6741")),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No jobs available."));
                }

                final jobDocs = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: jobDocs.map((jobDoc) {
                    final jobData = jobDoc.data() as Map<String, dynamic>;

                    return StreamBuilder<QuerySnapshot>(
                      stream: jobDoc.reference
                          .collection('applications')
                          .where('userId', isEqualTo: userId)
                          .snapshots(),
                      builder: (context, appSnap) {
                        if (!appSnap.hasData || appSnap.data!.docs.isEmpty) {
                          return const SizedBox(); // skip jobs not applied to
                        }

                        final appData = appSnap.data!.docs.first.data()
                            as Map<String, dynamic>;
                        final appliedDate =
                            (appData['appliedAt'] as Timestamp?)?.toDate();

                        final jobTitle =
                            (jobData['title'] ?? "").toString().toLowerCase();
                        final jobStatus =
                            (appData['status'] ?? "").toString().toLowerCase();

                        // 🔎 Apply search filter
                        if (searchQuery.isNotEmpty &&
                            !jobTitle.contains(searchQuery) &&
                            !jobStatus.contains(searchQuery)) {
                          return const SizedBox();
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WomanViewJobScreen(
                                  jobId: jobDoc.id,
                                ),
                              ),
                            );
                          },
                          child: buildWhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(jobData['title'] ?? "No Title",
                                    style: kTitleTextStyle),
                                vSpace(6),
                                Text("Location: ${jobData['location']}"),
                                Text("Salary: RM ${jobData['salary']}"),
                                Text("Status: ${appData['status']}"),
                                if (appliedDate != null)
                                  Text(
                                    "Applied on: ${appliedDate.day}/${appliedDate.month}/${appliedDate.year}",
                                    style: kSmallTextStyle,
                                  ),

                                // Add/Edit review button if accepted
                                if (appData['status'] == "accepted")
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('companyReviews')
                                        .where('companyId',
                                            isEqualTo: jobData['employerID'])
                                        .where('womanId', isEqualTo: userId)
                                        .snapshots(),
                                    builder: (context, reviewSnap) {
                                      if (!reviewSnap.hasData)
                                        return const SizedBox();

                                      final existingReview =
                                          reviewSnap.data!.docs.isNotEmpty
                                              ? reviewSnap.data!.docs.first
                                              : null;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.rate_review),
                                            label: Text(
                                              existingReview == null
                                                  ? "Add Review"
                                                  : "Edit Review",
                                            ),
                                            onPressed: () {
                                              _showAddOrEditReviewDialog(
                                                context,
                                                companyId:
                                                    jobData['employerID'],
                                                womanId: userId,
                                                existingReview: existingReview,
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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

  /// Show dialog to add or edit review
  void _showAddOrEditReviewDialog(
    BuildContext context, {
    required String companyId,
    required String womanId,
    DocumentSnapshot? existingReview,
  }) {
    final commentCtrl = TextEditingController(
      text: existingReview != null ? (existingReview['comment'] ?? "") : "",
    );

    int rating = existingReview != null ? existingReview['rating'] ?? 0 : 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existingReview == null ? "Leave a Review" : "Edit Review",
              style: kTitleTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    ),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Write your review here",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: Text(existingReview == null ? "Submit" : "Update"),
              onPressed: () async {
                if (existingReview == null) {
                  // Create new review
                  await FirebaseFirestore.instance
                      .collection('companyReviews')
                      .add({
                    'companyId': companyId,
                    'womanId': womanId,
                    'rating': rating,
                    'comment': commentCtrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // Update existing review
                  await existingReview.reference.update({
                    'rating': rating,
                    'comment': commentCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingReview == null
                        ? "Review submitted"
                        : "Review updated"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
