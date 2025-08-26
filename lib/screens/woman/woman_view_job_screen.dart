import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WomanViewJobScreen extends StatelessWidget {
  final String jobId;
  const WomanViewJobScreen({super.key, required this.jobId});

  Future<void> _applyForJob(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to apply.")),
      );
      return;
    }

    final userId = user.uid;

    // 🔹 Check if resume exists in womanProfiles
    final userDoc = await FirebaseFirestore.instance
        .collection('womanProfiles')
        .doc(userId)
        .get();

    if (!userDoc.exists ||
        (userDoc.data()?['resume'] == null ||
            userDoc.data()?['resume'] == "")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Please upload a resume to your profile before applying."),
        ),
      );
      return;
    }

    // 🔹 Save application under jobs/{jobId}/applications/{userId}
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection('applications')
        .doc(userId) // use userId as docId so a user can only apply once
        .set({
      "userId": userId,
      "appliedAt": FieldValue.serverTimestamp(),
      "status": "pending",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Application submitted successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Job not found')),
          );
        }

        Map<String, dynamic> jobData =
            jobSnapshot.data!.data() as Map<String, dynamic>;

        String employerId = jobData['employerID'] ?? '';
        String postedDate = '';
        if (jobData['postedAt'] != null) {
          Timestamp timestamp = jobData['postedAt'];
          DateTime date = timestamp.toDate();
          postedDate = '${date.day}/${date.month}/${date.year}';
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('companyProfiles')
              .doc(employerId)
              .get(),
          builder: (context, companySnapshot) {
            if (companySnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            Map<String, dynamic> companyData = {};
            if (companySnapshot.hasData && companySnapshot.data!.exists) {
              companyData =
                  companySnapshot.data!.data() as Map<String, dynamic>;
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Job Details',
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: hexToColor("#4a6741"),
                  ),
                ),
                backgroundColor: hexToColor("#dddddd"),
                iconTheme: IconThemeData(
                  color: hexToColor("#4a6741"),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Job Info Section =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            jobData['title'] ?? 'No Title',
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hexToColor("#a3ab94"),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            jobData['type'] ?? 'N/A',
                            style: GoogleFonts.lato(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location & Salary
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 20, color: hexToColor("#4a6741")),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                jobData['location'] ?? 'Not specified',
                                style: GoogleFonts.lato(
                                    fontSize: 15, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                size: 20, color: hexToColor("#4a6741")),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                jobData['salary'] ?? 'Not specified',
                                style: GoogleFonts.lato(
                                    fontSize: 15, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      "Description:",
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      jobData['description'],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 12),

                    // Required Skills
                    Text(
                      "Required Skills:",
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: (jobData['requiredSkills'] as List? ?? [])
                          .map((skill) => Chip(
                                label: Text(
                                  skill,
                                  style: GoogleFonts.lato(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                backgroundColor: hexToColor("#e0e0e0"),
                              ))
                          .toList(),
                    ),

                    // Posted Date
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        postedDate.isNotEmpty
                            ? 'Posted on: $postedDate'
                            : 'Posted on: -',
                        style: GoogleFonts.lato(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== Apply Button =====
                    if (user != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('jobs')
                            .doc(jobId)
                            .collection('applications')
                            .doc(user.uid)
                            .snapshots(), // 👈 real-time stream
                        builder: (context, appSnapshot) {
                          if (appSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final hasApplied = appSnapshot.data?.exists ?? false;

                          return Center(
                            child: SizedBox(
                              width: double.infinity, // Full width
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasApplied
                                      ? hexToColor('#4f4f4d')
                                      : hexToColor("#a3ab94"),
                                  disabledBackgroundColor:
                                      hexToColor('#4f4f4d'),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                ),
                                onPressed: hasApplied
                                    ? null
                                    : () => _applyForJob(context),
                                child: Text(
                                  hasApplied ? "Applied" : "Apply",
                                  style: GoogleFonts.openSans(
                                    textStyle: TextStyle(
                                      fontSize: 15,
                                      color: hexToColor("#f5f2e9"),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 20),

                    // ===== Company Info Section =====
                    if (companyData.isNotEmpty) ...[
                      Text(
                        'Company Information',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if ((companyData['companyLogo'] ?? '').isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                companyData['companyLogo'],
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              companyData['companyName'] ?? 'N/A',
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: 20, color: hexToColor("#4a6741")),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              companyData['companyAddress'] ?? 'N/A',
                              style: GoogleFonts.lato(
                                  fontSize: 15, color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((companyData['companyWebsite'] ?? '').isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.language_rounded,
                                size: 20, color: hexToColor("#4a6741")),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final url = companyData['companyWebsite'];
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  }
                                },
                                child: Text(
                                  companyData['companyWebsite'],
                                  style: GoogleFonts.lato(
                                      fontSize: 15, color: Colors.grey[800]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Description:",
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            companyData['companyDescription'] ?? 'N/A',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
