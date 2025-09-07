import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_view_ngo_details_page.dart';
import 'woman_my_requests_page.dart'; // <-- create this page to show her requests

class WomanViewNGOPage extends StatefulWidget {
  const WomanViewNGOPage({Key? key}) : super(key: key);

  @override
  _WomanViewNGOPageState createState() => _WomanViewNGOPageState();
}

class _WomanViewNGOPageState extends State<WomanViewNGOPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(
        title: "View NGOs",
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          buildSearchBar(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            hintText: "Search NGO by name",
          ),

// Button
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4), // smaller padding
            child: bigGreyButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WomanMyRequestsPage(),
                  ),
                );
              },
              label: "View My Requests",
            ),
          ),

          // NGO List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngoProfiles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final ngos = snapshot.data?.docs ?? [];

                // Filter NGOs based on search query
                final filteredNGOs = ngos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? '';
                  return name.toLowerCase().contains(searchQuery);
                }).toList();

                if (filteredNGOs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group,
                            size: 64, color: hexToColor('#a3ab94')),
                        SizedBox(height: 16),
                        Text(
                          "No NGOs found.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  itemCount: filteredNGOs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredNGOs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown NGO';
                    final phone = data['phone'] ?? '';
                    final description = data['description'] ?? '';
                    final imageUrl = data['profileImage'] ?? '';

                    return buildStyledCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WomanViewNGODetailsPage(
                                ngoId: filteredNGOs[index].id,
                                name: name,
                                phone: phone,
                                description: description,
                                imageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          radius: 35,
                          backgroundColor: imageUrl.isEmpty
                              ? hexToColor('#f0f0f0')
                              : Colors.transparent,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.group,
                                  size: 45, color: hexToColor('#a3ab94'))
                              : null,
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
