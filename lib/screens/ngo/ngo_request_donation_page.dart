import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:women_safety_empowerment_app/screens/ngo/ngo_donation_details_page.dart';
import 'package:women_safety_empowerment_app/screens/ngo/ngo_request_details_page.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class NGORequestDonationPage extends StatefulWidget {
  const NGORequestDonationPage({Key? key}) : super(key: key);

  @override
  _NGORequestDonationPageState createState() => _NGORequestDonationPageState();
}

class _NGORequestDonationPageState extends State<NGORequestDonationPage> {
  final categories = [
    "Funds",
    "Sanitary Products",
    "Clothes",
    "Essentials",
    "Food",
    "Medicine",
    "Shelter Supplies",
    "Other",
  ];

  final statuses = ["In Progress", "Completed"];

  String? selectedCategory;
  String? selectedStatus;
  String? selectedItem;

  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController filterItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filterItemController.addListener(() {
      selectedItem = filterItemController.text;
    });
  }

  Future<void> _showRequestDialog({DocumentSnapshot? doc}) async {
    String? category;
    bool canEditOrDelete = true; // NEW: control editing & delete

    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      category = data['category'];
      itemController.text = data['item'] ?? '';
      quantityController.text = data['quantity']?.toString() ?? '';
      descriptionController.text = data['description'] ?? '';

      // NEW: check if donations exist for this contribution
      final donationsSnap = await FirebaseFirestore.instance
          .collection('contributions')
          .doc(doc.id)
          .collection('donations')
          .get();
      final hasDonations = donationsSnap.docs.isNotEmpty;
      final status = data['status'] ?? 'In Progress';
      canEditOrDelete = status == 'In Progress' && !hasDonations;
    } else {
      category = null;
      itemController.clear();
      quantityController.clear();
      descriptionController.clear();
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            doc == null ? "Post Donation Request" : "Edit Donation Request",
            style: kTitleTextStyle,
          ),
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
                    onChanged: canEditOrDelete
                        ? (val) => setDialogState(() => category = val)
                        : null, // NEW
                    validator: (val) =>
                        val == null ? "Please select a category" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: itemController,
                    decoration: const InputDecoration(
                      labelText: "Item (e.g. Rice, Pads)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Please enter item" : null,
                    enabled: canEditOrDelete, // NEW
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? "Please enter quantity"
                        : null,
                    enabled: canEditOrDelete, // NEW
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
                      validator: (val) => val == null || val.isEmpty
                          ? "Please enter details"
                          : null,
                      // enabled: canEditOrDelete, // NEW
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            // NEW: Delete button
            if (doc != null && canEditOrDelete)
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('contributions')
                      .doc(doc.id)
                      .delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Donation request is deleted")),
                  );
                },
                child: const Text("Delete"),
              ),

            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  final payload = {
                    'type': 'ngoRequest',
                    'ngoId': uid,
                    'category': category,
                    'item': itemController.text.trim(),
                    'quantity': int.parse(quantityController.text.trim()),
                    'fulfilledQuantity':
                        doc == null ? 0 : (doc['fulfilledQuantity'] ?? 0),
                    'status': doc == null
                        ? 'In Progress'
                        : (doc['status'] ?? 'In Progress'),
                    'description': descriptionController.text.trim(),
                    'createdAt': doc == null
                        ? FieldValue.serverTimestamp()
                        : doc['createdAt'],
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  if (doc == null) {
                    final docRef = await FirebaseFirestore.instance
                        .collection('contributions')
                        .add(payload);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('contributions')
                        .doc(doc.id)
                        .update(payload);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          doc == null ? "Request Posted" : "Request Updated"),
                    ),
                  );
                }
              },
              child: Text(doc == null ? "Post" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contributions')
            .where('ngoId', isEqualTo: uid)
            .where('type', isEqualTo: 'ngoRequest')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No donation requests posted yet.",
                  style: kSubtitleTextStyle),
            );
          }

          final allRequests = snapshot.data!.docs;

          // --- Filter based on dropdown selections ---
          final filteredRequests = allRequests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final item = (data['item'] ?? "").toString();
            final category = (data['category'] ?? "").toString();
            final status = (data['status'] ?? "").toString();

            final matchesCategory =
                selectedCategory == null || selectedCategory == category;
            final matchesStatus =
                selectedStatus == null || selectedStatus == status;
            final matchesItem = filterItemController.text.isEmpty ||
                item
                    .toLowerCase()
                    .contains(filterItemController.text.toLowerCase());

            return matchesCategory && matchesStatus && matchesItem;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      hint: const Text("Filter by Category"),
                      items: [null, ...categories]
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c ?? "All Categories"),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 8),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      hint: const Text("Filter by Status"),
                      items: [null, ...statuses]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s ?? "All Statuses"),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedStatus = val),
                    ),
                    const SizedBox(height: 8),

                    // Item Text Field for partial match
                    TextField(
                      controller: filterItemController,
                      decoration: const InputDecoration(
                        hintText: "Search by Item",
                        border: OutlineInputBorder(),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: filterItemController,
                    builder: (context, value, _) {
                      final search = value.text.toLowerCase();

                      final filteredRequests = allRequests.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final item =
                            (data['item'] ?? "").toString().toLowerCase();
                        final category = (data['category'] ?? "").toString();
                        final status = (data['status'] ?? "").toString();

                        final matchesCategory = selectedCategory == null ||
                            selectedCategory == category;
                        final matchesStatus =
                            selectedStatus == null || selectedStatus == status;
                        final matchesItem =
                            search.isEmpty || item.contains(search);

                        return matchesCategory && matchesStatus && matchesItem;
                      }).toList();

                      if (filteredRequests.isEmpty) {
                        return const Center(
                            child: Text("No matching requests found"));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final doc = filteredRequests[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return buildWhiteCard(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(data['item'],
                                          style: kTitleTextStyle),
                                      buildGreenChip(
                                          data['status'] ?? 'In Progress'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: "Category: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(text: data['category'] ?? ""),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Quantity
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                          text: "Quantity: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                            text: "${data['quantity'] ?? 0}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Fulfilled Quantity
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                          text: "Fulfilled Quantity: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                            text:
                                                "${data['fulfilledQuantity'] ?? 0}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Available Quantity
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                          text: "Available Quantity: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                            text:
                                                "${data['availableQuantity'] ?? 0}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: "Description: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text: data['description'] ?? ""),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Posted On
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          const TextStyle(color: Colors.black),
                                      children: [
                                        const TextSpan(
                                          text: "Posted On: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: data['createdAt'] != null &&
                                                  data['createdAt'] is Timestamp
                                              ? DateFormat('dd MMM yyyy')
                                                  .format((data['createdAt']
                                                          as Timestamp)
                                                      .toDate())
                                              : "Unknown",
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DonationDetailsPage(
                                                      requestId: doc.id),
                                            ),
                                          );
                                        },
                                        child: const Text("View Donations"),
                                      ),

                                      // Show “View Requests” if status is Completed
                                      if ((data['status'] ?? '') == 'Completed')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    RequestDetailsPage(
                                                        requestId: doc.id),
                                              ),
                                            );
                                          },
                                          child: const Text("View Requests"),
                                        ),

                                      if (data['status'] != 'Completed')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 12),
                                          ),
                                          onPressed: () =>
                                              _showRequestDialog(doc: doc),
                                          child: const Text("Edit Donation"),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
              )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hexToColor("#a3ab94"),
        onPressed: () => _showRequestDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
