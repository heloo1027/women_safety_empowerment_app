import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Import auth
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
        const SnackBar(content: Text("You must be logged in to make a request")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('womanRequests').add({
        "ngoId": widget.ngoId,
        "womanId": user.uid, // ✅ Save the logged-in woman’s UID
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
      appBar: AppBar(title: const Text("NGO Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: widget.imageUrl.isNotEmpty
                    ? NetworkImage(widget.imageUrl)
                    : null,
                child: widget.imageUrl.isEmpty
                    ? const Icon(Icons.group, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(widget.phone, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.description, style: const TextStyle(fontSize: 16)),

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
                  return const Text("No open or in-progress donation requests.");
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
                                      receiverId: widget.ngoId,
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

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Request Donation from NGO",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
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
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter item" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter quantity" : null,
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
                  ElevatedButton.icon(
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Request"),
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
