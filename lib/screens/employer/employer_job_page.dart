import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_edit_job_page.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_post_job_page.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_view_job_applications_page.dart';

// Stateful widget for managing and displaying employer's posted jobs
class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  // Controller for search input
  final TextEditingController _searchController = TextEditingController();

  // Current search query for filtering jobs
  String _searchQuery = "";

  // Helper function to show a SnackBar message
  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      // Floating action button to post a new job
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String uid = FirebaseAuth.instance.currentUser!.uid;

          // Check company profile before allowing post
          DocumentSnapshot companyDoc = await FirebaseFirestore.instance
              .collection('companyProfiles')
              .doc(uid)
              .get();

          if (!companyDoc.exists) {
            _showSnack(context,
                "Please complete your company profile before posting jobs.");
            return;
          }

          var data = companyDoc.data() as Map<String, dynamic>?;

          // List of required company profile fields
          List<String> requiredFields = [
            'companyAddress',
            'companyDescription',
            'companyName',
            'companyWebsite',
          ];

          // Verify that all required fields are filled
          bool allFilled = requiredFields.every((field) =>
              data![field] != null && data[field].toString().trim().isNotEmpty);

          if (!allFilled) {
            _showSnack(context,
                "Please complete all company profile details before posting jobs.");
            return;
          }

          // Navigate to the job posting form
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostJobFormPage()),
          );
        },
        backgroundColor: hexToColor("#4f4f4d"),
        child: Icon(Icons.add, color: hexToColor("#dddddd")),
      ),

      body: Column(
        children: [
          // Search bar at the top to filter jobs by title, location, type, or status
          buildSearchBar(
            controller: _searchController,
            hintText: "Search jobs by title, location, type, status",
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),

          // Expanded widget to display the list of jobs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Fetch jobs posted by the current employer, ordered by posted date
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('employerID', isEqualTo: uid)
                  .orderBy('postedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Show loading indicator while fetching data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: hexToColor("#4a6741"),
                    ),
                  );
                }

                // Show message if no jobs are posted
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No jobs posted yet.\nTap + to post a job!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                // Apply filtering
                final jobs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final location =
                      (data['location'] ?? '').toString().toLowerCase();
                  final status =
                      (data['status'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();

                  return title.contains(_searchQuery) ||
                      location.contains(_searchQuery) ||
                      status.contains(_searchQuery) ||
                      type.contains(_searchQuery);
                }).toList();

                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      "No jobs found for '$_searchQuery'",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: jobs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    // Format timestamp
                    String postedDate = '';
                    if (data['postedAt'] != null) {
                      Timestamp timestamp = data['postedAt'];
                      DateTime date = timestamp.toDate();
                      postedDate = '${date.day}/${date.month}/${date.year}';
                    }

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row with Job Title & Edit Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? 'No Title',
                                    style: GoogleFonts.openSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: hexToColor("#4f4f4d")),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditJobPage(
                                            jobData: data, jobId: doc.id),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Job type & status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hexToColor("#a3ab94"),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['type'] ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hexToColor("#e5ba9f"),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['status'] ?? 'Open',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Salary, location, description
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                    children: [
                                      const TextSpan(
                                        text: 'Salary: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                              'RM ${data['salary'] ?? 'N/A'}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                    children: [
                                      const TextSpan(
                                        text: 'Location: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: data['location'] ?? 'N/A'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                if ((data['description'] ?? '').isNotEmpty)
                                  Container(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          height: 1.5,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Description: \n',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: data['description']),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),

                                // Divider before skills
                                if (data['requiredSkills'] != null &&
                                    (data['requiredSkills'] as List).isNotEmpty)
                                  Divider(
                                      color: Colors.grey[300],
                                      height: 16,
                                      thickness: 1),

                                // Skills label
                                if (data['requiredSkills'] != null &&
                                    (data['requiredSkills'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'Required Skills:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                // Skills chips
                                if (data['requiredSkills'] != null &&
                                    (data['requiredSkills'] as List).isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: (data['requiredSkills'] as List)
                                        .map((skill) {
                                      return Chip(
                                        label: Text(skill),
                                        backgroundColor: hexToColor("#dddddd"),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Applications Button (below skills)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    hexToColor("#4a6741"), // green button
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.people, size: 18),
                              label: const Text("View Applications"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EmployerViewJobApplicationsPage(
                                      jobId: doc.id,
                                      employerId:
                                          uid, // pass current employer id
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // Posted date
                            if (postedDate.isNotEmpty)
                              Text(
                                'Posted on: $postedDate',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
