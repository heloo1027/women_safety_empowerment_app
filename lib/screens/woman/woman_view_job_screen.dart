import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class WomanViewJobScreen extends StatelessWidget {
  final String jobId;
  const WomanViewJobScreen({super.key, required this.jobId});

  Future<void> _applyForJob(BuildContext context, String jobId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must be logged in to apply.")),
    );
    return;
  }

  final userId = user.uid;

  // 🔹 Fetch user profile
  final userDoc = await FirebaseFirestore.instance
      .collection('womanProfiles')
      .doc(userId)
      .get();

  if (!userDoc.exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please complete your profile before applying."),
      ),
    );
    return;
  }

  final data = userDoc.data() ?? {};

  // 🔹 Validate required fields
  final resume = data['resume'];
  final education = data['education'];
  final skills = data['skills'];
  final languages = data['languages'];

  if (resume == null || resume.toString().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please upload a resume before applying.")),
    );
    return;
  }

  if (education == null ||
      education['course'] == null ||
      education['course'].toString().isEmpty ||
      education['institution'] == null ||
      education['institution'].toString().isEmpty ||
      education['expectedFinish'] == null ||
      education['expectedFinish'].toString().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please complete your education details.")),
    );
    return;
  }

  if (skills == null || (skills is List && skills.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please add at least one skill.")),
    );
    return;
  }

  if (languages == null || (languages is List && languages.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please add at least one language.")),
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
              appBar: buildStyledAppBar(title: "Job Details"),
              body: SingleChildScrollView(
                padding: kPagePadding,
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
                    vSpace(8),

                    // Location & Salary
                    buildInfoRow(
                      text: jobData['location'] ?? 'Not specified',
                      icon: Icons.location_on,
                    ),
                    vSpace(6),
                    buildInfoRow(
                      text: jobData['salary'] != null
                          ? 'RM ${jobData['salary']}'
                          : 'Not specified',
                      icon: Icons.money_rounded,
                    ),
                    vSpace(12),

                    // Description
                    buildSectionTitle("Description:"),
                    vSpace(6),
                    Text(
                      jobData['description'],
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    vSpace(12),

                    // Required Skills
                    buildSectionTitle("Required Skills:"),
                    vSpace(6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: (jobData['requiredSkills'] as List? ?? [])
                          .map((skill) => buildStyledChip(skill))
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
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                    vSpace(12),

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
                            child: bigGreyButton(
                              onPressed: hasApplied
                                  ? null
                                  : () => _applyForJob(context, jobId),
                              label: hasApplied ? "Applied" : "Apply",
                            ),
                          );
                        },
                      ),

                    Divider(color: Colors.grey[400]),
                    vSpace(20),

                    // ===== Company Info Section =====
                    if (companyData.isNotEmpty) ...[
                      // buildSectionTitle('Company Information'),
                      // vSpace(16),
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
                      vSpace(12),
                      buildInfoRow(
                        text: companyData['companyAddress'] ?? 'N/A',
                        icon: Icons.location_on,
                      ),
                      vSpace(10),
                      if ((companyData['companyWebsite'] ?? '').isNotEmpty)
                        buildInfoRow(
                          text: companyData['companyWebsite'],
                          icon: Icons.language_rounded,
                        ),
                      vSpace(10),
                      buildSectionTitle("Description:"),
                      vSpace(6),
                      Text(
                        companyData['companyDescription'] ?? 'N/A',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      vSpace(24),
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
