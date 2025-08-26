import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_view_job_screen.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

class WomanJobScreen extends StatelessWidget {
  const WomanJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
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
              final data =
                  doc.data() != null ? doc.data() as Map<String, dynamic> : {};

              // Format timestamp safely
              String postedDate = '';
              if (data['postedAt'] != null && data['postedAt'] is Timestamp) {
                Timestamp timestamp = data['postedAt'] as Timestamp;
                DateTime date = timestamp.toDate();
                postedDate = '${date.day}/${date.month}/${date.year}';
              }

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WomanViewJobScreen(jobId: doc.id),
                    ),
                  );
                },
                child: Card(
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
                        // Title & Type
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Salary
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                    size: 20, color: hexToColor("#4a6741")),
                                    Text('RM ${data['salary'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(height: 6),
                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                    size: 20, color: hexToColor("#4a6741")),
                                    Text('${data['location'] ?? 'N/A'}'),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(height: 6),
                        // Posted Date
                        if (postedDate.isNotEmpty)
                          Text(
                            'Posted on: $postedDate',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
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
