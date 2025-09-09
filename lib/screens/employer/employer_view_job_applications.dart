import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'employer_chat_page.dart';

// Import your chat page
// import 'chat_page.dart'; // 🔹 Make sure to create this screen

class EmployerViewJobApplicationsPage extends StatelessWidget {
  final String jobId; // Pass this when navigating
  final String employerId; // ✅ Pass employerId when opening this page

  const EmployerViewJobApplicationsPage({
    Key? key,
    required this.jobId,
    required this.employerId,
  }) : super(key: key);

  // Function to launch resume URL
  Future<void> _openResume(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded.")),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open resume.")),
      );
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "Unknown";
    final dt = ts.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
  }

  // 🔹 Update status in Firestore
  Future<void> _updateStatus(
      String jobId, String userId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection('applications')
        .doc(userId)
        .update({"status": newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: 'Job Applications'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .collection('applications')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = snapshot.data!.docs;

          if (applications.isEmpty) {
            return const Center(child: Text("No applications yet."));
          }

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final appDoc = applications[index];
              final appData = appDoc.data() as Map<String, dynamic>;
              final userId = appData['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('womanProfiles') // ✅ fetch from womanProfiles
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return const ListTile(title: Text("User not found"));
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    userData['profileImage'] != null &&
                                            userData['profileImage']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(userData['profileImage'])
                                        : null,
                                backgroundColor: Colors.grey.shade300,
                                child: (userData['profileImage'] == null ||
                                        userData['profileImage']
                                            .toString()
                                            .isEmpty)
                                    ? Text(
                                        userData['name'] != null
                                            ? userData['name'][0].toUpperCase()
                                            : "?",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData['name'] ?? "No Name",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    if (userData['phone'] != null)
                                      Text("📞 ${userData['phone']}"),
                                    if (userData['email'] != null)
                                      Text(userData['email'],
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.description_outlined),
                                onPressed: () =>
                                    _openResume(context, userData['resume']),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 🔹 Application details
                          Row(
                            children: [
                              const Text("Status: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: appData['status'],
                                items: const [
                                  DropdownMenuItem(
                                      value: "pending", child: Text("Pending")),
                                  DropdownMenuItem(
                                      value: "accepted",
                                      child: Text("Accepted")),
                                  DropdownMenuItem(
                                      value: "rejected",
                                      child: Text("Rejected")),
                                ],
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    _updateStatus(jobId, userId, newValue);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Text(
                            "Applied at: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(appData['appliedAt']),
                          ),

                          const SizedBox(height: 10),

                          // 🔹 Education
                          if (userData['education'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Education",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    "${userData['education']['course'] ?? ''} at ${userData['education']['institution'] ?? ''}"),
                                if (userData['education']['expectedFinish'] !=
                                    null)
                                  const SizedBox(height: 10),
                                const Text(
                                  "Expected Finish: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  userData['education']['expectedFinish'] ??
                                      'N/A',
                                ),
                              ],
                            ),

                          const SizedBox(height: 8),

                          // 🔹 Skills
                          if (userData['skills'] != null &&
                              (userData['skills'] as List).isNotEmpty) ...[
                            const Text("Skills",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 6,
                              children:
                                  (userData['skills'] as List).map((skill) {
                                return Chip(
                                  label: Text(skill),
                                  backgroundColor: hexToColor("#a3ab94"),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // 🔹 Languages
                          if (userData['languages'] != null &&
                              (userData['languages'] as List).isNotEmpty) ...[
                            const Text("Languages",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 6,
                              children:
                                  (userData['languages'] as List).map((lang) {
                                return Chip(
                                  label: Text(lang),
                                  backgroundColor: hexToColor("#e5ba9f"),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // 🔹 Chat Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text("Chat"),
                              onPressed: () {
                                // 🔹 Navigate to chat screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployerChatPage(
                                      employerId: employerId,
                                      applicantId: userId,
                                      receiverName: userData['name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
