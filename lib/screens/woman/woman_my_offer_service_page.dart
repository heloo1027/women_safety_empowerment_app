// This page is to offer a new service or edit/delete existing services
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class WomanMyManageServicePage extends StatefulWidget {
  final String? serviceId; // null = add new
  const WomanMyManageServicePage({
    super.key,
    this.serviceId,
    required String userId,
    required Map existingData,
  });

  @override
  _WomanMyManageServicePageState createState() =>
      _WomanMyManageServicePageState();
}

class _WomanMyManageServicePageState extends State<WomanMyManageServicePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    "Plumbing",
    "Tutoring",
    "Home Repairs",
    "Cooking",
    "Child Care",
    "Cleaning",
    "Electrical Work",
    "Gardening",
    "Pet Care",
    "Beauty & Spa",
    "Transportation",
    "Tech Support",
    "Event Planning",
    "Handyman Services",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceId != null) {
      _fetchService();
    }
  }

  Future<void> _fetchService() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _priceController.text = data['price'] ?? '';
        _selectedCategory = data['category'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading service: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (widget.serviceId == null) {
        // ➕ Add new service
        await FirebaseFirestore.instance.collection('services').add({
          'userId': user.uid,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': _priceController.text.trim(),
          'category': _selectedCategory,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service added successfully!")),
        );
      } else {
        // ✏️ Update existing service
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.serviceId)
            .update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': _priceController.text.trim(),
          'category': _selectedCategory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service updated successfully!")),
        );
      }

      Navigator.pop(context, true); //  go back to previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteService() async {
    if (widget.serviceId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Service", style: kTitleTextStyle,),
        content: const Text("Are you sure you want to delete this service?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.serviceId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service deleted successfully!")),
      );

      Navigator.pop(context, true); //  return to services list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting service: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: buildStyledAppBar(
        title: widget.serviceId == null ? "Offer a Service" : "Edit Service",
        actions: [
          if (widget.serviceId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteService,
            ),
        ],
      ),
      body: Padding(
        padding: kPagePadding,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Service Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (in RM)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a price" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Select Category",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a description" : null,
              ),
              const SizedBox(height: 12),
              bigGreyButton(
                onPressed: _saveService,
                label: widget.serviceId == null
                    ? "Offer Service"
                    : "Update Service",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
