import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_edit_job_sceen.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_post_job_screen.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_view_job_applications.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

class PostJobPage extends StatelessWidget {
  const PostJobPage({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostJobFormPage()),
          );
        },
        backgroundColor: hexToColor("#4f4f4d"),
        child: Icon(Icons.add, color: hexToColor("#dddddd")),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('employerID', isEqualTo: uid)
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: hexToColor("#4a6741"), // Green loader
              ),
            );
          }

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

          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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
                      // 🔹 Row with Job Title & Edit Button
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
                            icon:
                                Icon(Icons.edit, color: hexToColor("#4f4f4d")),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditJobPage(jobData: data, jobId: doc.id),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 🔹 Job type & status
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

                      // 🔹 Salary, location, description
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: 'RM ${data['salary'] ?? 'N/A'}'),
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                              children:
                                  (data['requiredSkills'] as List).map((skill) {
                                return Chip(
                                  label: Text(skill),
                                  backgroundColor: hexToColor("#dddddd"),
                                );
                              }).toList(),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 🔹 Applications Button (below skills)
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
                                employerId: uid, // ✅ pass current employer id
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // 🔹 Posted date
                      if (postedDate.isNotEmpty)
                        Text(
                          'Posted on: $postedDate',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
