import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'woman_view_ngo_details_page.dart'; // Import the details page

class WomanViewNGOPage extends StatefulWidget {
  const WomanViewNGOPage({Key? key}) : super(key: key);

  @override
  _WomanViewNGOPageState createState() => _WomanViewNGOPageState();
}

class _WomanViewNGOPageState extends State<WomanViewNGOPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View NGOs"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('ngoProfiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final ngos = snapshot.data?.docs ?? [];

          if (ngos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.group, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "You have no posted NGOs currently.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ngos.length,
            itemBuilder: (context, index) {
              final data = ngos[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown NGO';
              final phone = data['phone'] ?? '';
              final description = data['description'] ?? '';
              final imageUrl = data['profileImage'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WomanViewNGODetailsPage(
                          ngoId:
                              ngos[index].id, // pass the document ID as ngoId
                          name: name,
                          phone: phone,
                          description: description,
                          imageUrl: imageUrl,
                        ),
                      ),
                    );
                  },
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.group, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
