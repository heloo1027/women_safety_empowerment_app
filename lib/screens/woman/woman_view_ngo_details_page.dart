import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'woman_chat_page.dart'; // make sure this path matches your project

class WomanViewNGODetailsPage extends StatelessWidget {
  final String ngoId; // Add NGO ID to fetch requests
  final String name;
  final String phone;
  final String description;
  final String imageUrl;

  const WomanViewNGODetailsPage({
    Key? key,
    required this.ngoId,
    required this.name,
    required this.phone,
    required this.description,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.group, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(phone, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              "Donation Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// Show only 'Open' and 'In Progress' requests
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngoRequests')
                  .where('ngoId', isEqualTo: ngoId)
                  .where('status', whereIn: ['Open', 'In Progress'])
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                final requests = snapshot.data?.docs ?? [];

                if (requests.isEmpty) {
                  return const Text(
                      "No open or in-progress donation requests.");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data =
                        requests[index].data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(data['category'] ?? "Unknown"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${data['status'] ?? 'N/A'}"),
                            const SizedBox(height: 4),
                            Text(data['description'] ?? ""),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (createdAt != null)
                              Text(
                                "${createdAt.day}/${createdAt.month}/${createdAt.year}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WomanChatPage(
                                      receiverId: ngoId, // ngoId for chat
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
