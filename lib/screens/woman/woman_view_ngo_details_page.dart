import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Import auth
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'woman_chat_page.dart';

class WomanViewNGODetailsPage extends StatefulWidget {
  final String ngoId;
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
  State<WomanViewNGODetailsPage> createState() =>
      _WomanViewNGODetailsPageState();
}

class _WomanViewNGODetailsPageState extends State<WomanViewNGODetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Dropdown + Text Controllers
  String? _selectedCategory;
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _categories = [
    "Funds",
    "Sanitary Products",
    "Clothes",
    "Essentials",
    "Food",
    "Medicine",
    "Shelter Supplies",
    "Other",
  ];

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser; // ✅ Get logged in user
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You must be logged in to make a request")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('womanRequests').add({
        "ngoId": widget.ngoId,
        "womanId": user.uid, //  Save the logged-in woman’s UID
        "category": _selectedCategory,
        "item": _itemController.text.trim(),
        "quantity": _quantityController.text.trim(),
        "description": _descriptionController.text.trim(),
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      _itemController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(
        title: "NGO Details",
        actions: [
          IconButton(
            icon: Icon(Icons.chat, color: hexToColor('#4a6741')),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WomanChatPage(
                    receiverId: widget.ngoId,
                    receiverName: widget.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NGO image + name row
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.imageUrl.isNotEmpty
                      ? NetworkImage(widget.imageUrl)
                      : null,
                  child: widget.imageUrl.isEmpty
                      ? const Icon(Icons.group, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Phone row
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(widget.phone, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            // Description with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Icon(Icons.description, size: 20),
                // const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.description,
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(
              color: hexToColor('#4a6741'),
              thickness: 1,
            ),

            // Donation Requests title
            Padding(
              padding:
                  const EdgeInsets.only(left: 7.0), // 👈 adjust value as needed
              child: const Text(
                "Donate to us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: const Text(
                "We are currently receiving donations for items below",
                style: TextStyle(
                    fontSize: 11,
                    // fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngoRequests')
                  .where('ngoId', isEqualTo: widget.ngoId)
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
                  return const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "No open or in-progress donation requests.",
                    ),
                  );
                }

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] != null
                        ? (data['createdAt'] as Timestamp).toDate()
                        : null;
                    final postedDate = createdAt != null
                        ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                        : '';

                    return buildWhiteCard(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category row with badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['category'] ?? 'Unknown',
                                  style: GoogleFonts.openSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                                  data['status'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Item/Description
                          Text(
                            "${data['description'] ?? ''}",
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                          const SizedBox(height: 6),

                          // Date at bottom right
                          if (postedDate.isNotEmpty)
                            Text(
                              'Posted on: $postedDate',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            // Divider(
            //   color: hexToColor('#4a6741'),
            //   thickness: 1,
            // ),

            // Request Donation from NGO Form Card
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: const Text(
                "Request Donation from NGO",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(left: 8.0), // 👈 adjust value as needed
              child: const Text(
                "Send a donation request to us and we will reach you out",
                style: TextStyle(
                    fontSize: 11,
                    // fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            ),

            buildStyledCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: _categories
                              .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                          },
                          validator: (value) =>
                              value == null ? "Select a category" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _itemController,
                          decoration: const InputDecoration(
                            labelText: "Item (e.g., Rice, Pads, Jacket)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter item"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter quantity"
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter description"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        bigGreyButton(
                          onPressed: _submitRequest,
                          label: "Submit Request",
                        ),
                        const SizedBox(height: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
