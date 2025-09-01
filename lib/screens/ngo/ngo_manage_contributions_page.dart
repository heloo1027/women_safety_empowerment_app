import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NGOManageContributionsPage extends StatefulWidget {
  const NGOManageContributionsPage({Key? key}) : super(key: key);

  @override
  State<NGOManageContributionsPage> createState() =>
      _NGOManageContributionsPageState();
}

class _NGOManageContributionsPageState
    extends State<NGOManageContributionsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _donorContactController = TextEditingController();
  final TextEditingController _requesterNameController =
      TextEditingController();
  final TextEditingController _requesterContactController =
      TextEditingController();
  final TextEditingController _otherCategoryController =
      TextEditingController();

  String _type = "inflow"; // inflow = from donor, outflow = to requester
  String _selectedCategory = "Funds";

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

  Stream<QuerySnapshot> _fetchContributions() {
    return FirebaseFirestore.instance
        .collection('contributions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _addOrEditContribution({DocumentSnapshot? doc}) async {
    if (_formKey.currentState!.validate()) {
      final category = _selectedCategory == "Other"
          ? _otherCategoryController.text.trim()
          : _selectedCategory;

      final data = {
        "type": _type,
        "category": category,
        "item": _itemController.text.trim(),
        "description": _descriptionController.text.trim(),
        "quantity": int.tryParse(_quantityController.text.trim()) ?? 0,
        "status": "Pending",
        "donorName": _type == "inflow" ? _donorNameController.text.trim() : "",
        "donorContact":
            _type == "inflow" ? _donorContactController.text.trim() : "",
        "requesterName":
            _type == "outflow" ? _requesterNameController.text.trim() : "",
        "requesterContact":
            _type == "outflow" ? _requesterContactController.text.trim() : "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      if (doc == null) {
        await FirebaseFirestore.instance.collection('contributions').add(data);
      } else {
        await doc.reference.update(data);
      }

      // Clear fields
      _itemController.clear();
      _descriptionController.clear();
      _quantityController.clear();
      _donorNameController.clear();
      _donorContactController.clear();
      _requesterNameController.clear();
      _requesterContactController.clear();
      _otherCategoryController.clear();

      Navigator.pop(context);
    }
  }

  void _showAddOrEditDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      // Pre-fill fields for editing
      _type = doc['type'] ?? "inflow";
      _selectedCategory = doc['category'] ?? "Funds";
      _itemController.text = doc['item'] ?? "";
      _descriptionController.text = doc['description'] ?? "";
      _quantityController.text = "${doc['quantity'] ?? ""}";
      _donorNameController.text = doc['donorName'] ?? "";
      _donorContactController.text = doc['donorContact'] ?? "";
      _requesterNameController.text = doc['requesterName'] ?? "";
      _requesterContactController.text = doc['requesterContact'] ?? "";
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? "Add Contribution" : "Edit Contribution"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(
                        value: "inflow", child: Text("Incoming Donation")),
                    DropdownMenuItem(
                        value: "outflow", child: Text("Outgoing Donation")),
                  ],
                  onChanged: (val) => setState(() => _type = val!),
                  decoration:
                      const InputDecoration(labelText: "Contribution Type"),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                if (_selectedCategory == "Other")
                  TextFormField(
                    controller: _otherCategoryController,
                    decoration:
                        const InputDecoration(labelText: "Other Category"),
                    validator: (value) {
                      if (_selectedCategory == "Other" &&
                          (value == null || value.isEmpty)) {
                        return "Please enter a category";
                      }
                      return null;
                    },
                  ),
                TextFormField(
                  controller: _itemController,
                  decoration: const InputDecoration(labelText: "Item Name"),
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter item name"
                      : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter quantity"
                      : null,
                ),
                if (_type == "inflow") ...[
                  TextFormField(
                    controller: _donorNameController,
                    decoration: const InputDecoration(labelText: "Donor Name"),
                  ),
                  TextFormField(
                    controller: _donorContactController,
                    decoration:
                        const InputDecoration(labelText: "Donor Contact"),
                  ),
                ],
                if (_type == "outflow") ...[
                  TextFormField(
                    controller: _requesterNameController,
                    decoration:
                        const InputDecoration(labelText: "Requester Name"),
                  ),
                  TextFormField(
                    controller: _requesterContactController,
                    decoration:
                        const InputDecoration(labelText: "Requester Contact"),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => _addOrEditContribution(doc: doc),
              child: const Text("Save")),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCategoryItemSummary(
      List<QueryDocumentSnapshot> docs) {
    final summary = <String, Map<String, dynamic>>{};

    for (var doc in docs) {
      final category = doc['category'] ?? "Unknown";
      final item = doc['item'] ?? "Unknown";
      final qty = (doc['quantity'] ?? 0) as int;
      final type = doc['type'] ?? "inflow";
      final status = doc['status'] ?? "Pending";

      if (status == "Completed") {
        final adjQty = type == "inflow" ? qty : -qty;

        summary.putIfAbsent(
            category,
            () => {
                  "total": 0,
                  "items": <String, int>{},
                });

        // update category total
        summary[category]!["total"] =
            (summary[category]!["total"] as int) + adjQty;

        // update item total
        final items = summary[category]!["items"] as Map<String, int>;
        items[item] = (items[item] ?? 0) + adjQty;
      }
    }

    return summary;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Manage Contributions")),
    body: StreamBuilder<QuerySnapshot>(
      stream: _fetchContributions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.docs;

        if (data.isEmpty) {
          return const Center(child: Text("No contributions yet"));
        }

        final summary = _buildCategoryItemSummary(data);

        return Column(
          children: [
            // ✅ Show Summary
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("綜合 (Summary by Category & Item)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...summary.entries.map((catEntry) {
                      final category = catEntry.key;
                      final total = catEntry.value["total"] as int;
                      final items = catEntry.value["items"] as Map<String, int>;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$category: $total",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            ...items.entries.map((itemEntry) => Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                      "${itemEntry.key}: ${itemEntry.value}"),
                                )),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ✅ List of Contributions
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final contribution = data[index];
                  final type = contribution['type'] ?? "inflow";
                  final category = contribution['category'] ?? "";
                  final item = contribution['item'] ?? "Unknown";
                  final desc = contribution['description'] ?? "";
                  final quantity = contribution['quantity'] ?? 0;
                  final status = contribution['status'] ?? "Pending";

                  final donorName = contribution['donorName'] ?? "";
                  final donorContact = contribution['donorContact'] ?? "";
                  final requesterName = contribution['requesterName'] ?? "";
                  final requesterContact =
                      contribution['requesterContact'] ?? "";

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Icon(
                        type == "inflow"
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: type == "inflow" ? Colors.green : Colors.blue,
                      ),
                      title: Text("$category - $item ($quantity)"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (desc.isNotEmpty) Text(desc),
                          Text("Status: $status"),
                          if (type == "inflow" && donorName.isNotEmpty)
                            Text(
                                "From Donor: $donorName (${donorContact.isNotEmpty ? donorContact : '-'})"),
                          if (type == "outflow" && requesterName.isNotEmpty)
                            Text(
                                "To Requester: $requesterName (${requesterContact.isNotEmpty ? requesterContact : '-'})"),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == "markCompleted") {
                            await contribution.reference
                                .update({"status": "Completed"});
                          } else if (value == "edit") {
                            _showAddOrEditDialog(doc: contribution);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "markCompleted",
                            child: Text("Mark as Completed"),
                          ),
                          const PopupMenuItem(
                            value: "edit",
                            child: Text("Edit Contribution"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddOrEditDialog,
      child: const Icon(Icons.add),
    ),
  );
}
}
