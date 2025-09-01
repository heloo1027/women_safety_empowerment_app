import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NGORequestDonationPage extends StatefulWidget {
  const NGORequestDonationPage({Key? key}) : super(key: key);

  @override
  _NGORequestDonationPageState createState() => _NGORequestDonationPageState();
}

class _NGORequestDonationPageState extends State<NGORequestDonationPage> {
  final categories = [
    'Funds',
    'Sanitary Products',
    'Clothes',
    'Essentials',
    'Other'
  ];

  final statuses = ['Open', 'In Progress', 'Completed'];

  final _formKey = GlobalKey<FormState>();
  String? category;
  String? status;
  final descriptionController = TextEditingController();

  Future<void> _showRequestDialog({DocumentSnapshot? doc}) async {
    // If editing, preload the values
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      category = data['category'];
      status = data['status'];
      descriptionController.text = data['description'] ?? '';
    } else {
      category = null;
      status = null;
      descriptionController.clear();
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "Post Donation Request" : "Edit Donation Request"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => category = val),
                  validator: (val) =>
                      val == null ? "Please select a category" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => status = val),
                  validator: (val) =>
                      val == null ? "Please select a status" : null,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: TextFormField(
                    controller: descriptionController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter details" : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final uid = FirebaseAuth.instance.currentUser!.uid;

                if (doc == null) {
                  // Add new
                  await FirebaseFirestore.instance.collection('ngoRequests').add({
                    'ngoId': uid,
                    'category': category,
                    'status': status,
                    'description': descriptionController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  // Update existing
                  await FirebaseFirestore.instance
                      .collection('ngoRequests')
                      .doc(doc.id)
                      .update({
                    'category': category,
                    'status': status,
                    'description': descriptionController.text.trim(),
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(doc == null
                        ? "Request Posted"
                        : "Request Updated"),
                  ),
                );
              }
            },
            child: Text(doc == null ? "Post" : "Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Donation"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRequestDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ngoRequests')
            .where('ngoId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
                child: Text("No donation requests posted yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (createdAt != null)
                        Text(
                          "${createdAt.day}/${createdAt.month}/${createdAt.year}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRequestDialog(doc: doc),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
