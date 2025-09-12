import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_chat_page.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'ngo_chat_page.dart';

class NGOManageContributionsPage extends StatelessWidget {
  const NGOManageContributionsPage({Key? key}) : super(key: key);

  Future<void> _markAsCompleted(String docId, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Mark woman's request as completed
    await firestore.collection('contributions').doc(docId).update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update NGO request stock
    final category = data['category'];
    final item = data['item'];
    final qty = data['quantity'] ?? 0;
    final ngoId = data['ngoId'];

    if (data['type'] == 'womanRequest') {
      final snapshot = await firestore
          .collection('contributions')
          .where('ngoId', isEqualTo: ngoId)
          .where('type', isEqualTo: 'ngoRequest') // ✅ ensure only NGO requests
          .where('category', isEqualTo: category)
          .where('item', isEqualTo: item)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
        final ngoData = snapshot.docs.first.data() as Map<String, dynamic>;

        final fulfilled = (ngoData['fulfilledQuantity'] ?? 0) + qty;
        final requiredQty = ngoData['quantity'] ?? 0;

        await docRef.update({
          'fulfilledQuantity': fulfilled,
          'status': fulfilled >= requiredQty ? 'Completed' : 'In Progress',
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contributions')
            .where('ngoId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No contributions recorded yet."));
          }

          final contributions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: contributions.length,
            itemBuilder: (context, index) {
              final doc = contributions[index];
              final data = doc.data() as Map<String, dynamic>;

              final type =
                  data['type'] ?? 'Unknown'; // womanRequest / womanDonation
              final category = data['category'] ?? '-';
              final item = data['item'] ?? '-';
              final quantity = data['quantity']?.toString() ?? '-';
              final status = data['status'] ?? 'N/A';
              final description = data['description'] ?? '';
              final womanId = data['womanId'] ?? '';
              final createdAt = data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type + Status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(type,
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: type == 'womanRequest'
                                ? Colors.orange
                                : Colors.green,
                          ),
                          buildGreenChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: "Category: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: category),
                      ])),
                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: "Item: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: item),
                      ])),
                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: "Quantity: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: quantity),
                      ])),
                      if (description.isNotEmpty)
                        Text.rich(TextSpan(children: [
                          const TextSpan(
                              text: "Description: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: description),
                        ])),
                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            "Submitted on: ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                            style: kSmallTextStyle,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Actions: Chat + Complete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat, color: Colors.blue),
                            tooltip: "Chat with woman",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NGOChatPage(
                                    receiverId: womanId,
                                    receiverName:
                                        "Woman User", // ⚡ fetch name if you store it
                                  ),
                                ),
                              );
                            },
                          ),
                          if (status != 'Completed')
                            ElevatedButton(
                              onPressed: () => _markAsCompleted(doc.id, data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hexToColor("#a3ab94"),
                              ),
                              child: const Text("Mark as Completed"),
                            ),
                        ],
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

// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:women_safety_empowerment_app/utils/utils.dart';
// import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

// class NGOManageContributionsPage extends StatefulWidget {
//   const NGOManageContributionsPage({Key? key}) : super(key: key);

//   @override
//   State<NGOManageContributionsPage> createState() =>
//       _NGOManageContributionsPageState();
// }

// class _NGOManageContributionsPageState
//     extends State<NGOManageContributionsPage> {
//   final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = "";

//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _itemController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _donorNameController = TextEditingController();
//   final TextEditingController _donorContactController = TextEditingController();
//   final TextEditingController _requesterNameController =
//       TextEditingController();
//   final TextEditingController _requesterContactController =
//       TextEditingController();
//   final TextEditingController _otherCategoryController =
//       TextEditingController();

//   String _type = "inflow";
//   String _selectedCategory = "Funds";

//   final List<String> _categories = [
//     "Funds",
//     "Sanitary Products",
//     "Clothes",
//     "Essentials",
//     "Food",
//     "Medicine",
//     "Shelter Supplies",
//     "Other",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text.trim().toLowerCase();
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _itemController.dispose();
//     _descriptionController.dispose();
//     _quantityController.dispose();
//     _donorNameController.dispose();
//     _donorContactController.dispose();
//     _requesterNameController.dispose();
//     _requesterContactController.dispose();
//     _otherCategoryController.dispose();
//     super.dispose();
//   }

//   Stream<QuerySnapshot> _fetchContributions() {
//     return FirebaseFirestore.instance
//         .collection('contributions')
//         .where('userId', isEqualTo: currentUserId)
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }

//   bool _matchesSearch(DocumentSnapshot doc, String query) {
//     if (query.isEmpty) return true;
//     final lowercaseQuery = query.toLowerCase();

//     final item = (doc['item'] ?? '').toLowerCase();
//     final category = (doc['category'] ?? '').toLowerCase();
//     final status = (doc['status'] ?? '').toLowerCase();

//     return item.contains(lowercaseQuery) ||
//         category.contains(lowercaseQuery) ||
//         status.contains(lowercaseQuery);
//   }

//   /// --- Helper: Compute available items and stock for outflow ---
//   Map<String, int> _getAvailableItems(
//       List<QueryDocumentSnapshot> docs, String category) {
//     final Map<String, int> availableItems = {};

//     for (var doc in docs) {
//       if (doc['status'] != 'Completed') continue;
//       if (doc['category'] != category) continue;

//       final item = doc['item'] ?? "Unknown";
//       final qty = (doc['quantity'] ?? 0) as int;
//       final type = doc['type'] ?? "inflow";

//       if (type == "inflow") {
//         availableItems[item] = (availableItems[item] ?? 0) + qty;
//       } else if (type == "outflow") {
//         availableItems[item] = (availableItems[item] ?? 0) - qty;
//       }
//     }

//     availableItems.removeWhere((key, value) => value <= 0);
//     return availableItems;
//   }

//   Future<void> _addOrEditContribution({
//     DocumentSnapshot? doc,
//     required String type,
//     required String category,
//   }) async {
//     if (!_formKey.currentState!.validate()) return;

//     final finalCategory =
//         category == "Other" ? _otherCategoryController.text.trim() : category;

//     final int requestedQty = int.tryParse(_quantityController.text.trim()) ?? 0;
//     final String itemName = _itemController.text.trim();

//     int oldQty = 0;
//     String oldType = '';
//     if (doc != null) {
//       oldQty = (doc['quantity'] ?? 0) as int;
//       oldType = doc['type'] ?? '';
//     }

//     // --- Check stock for outgoing donations ---
//     if (type == "outflow") {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('contributions')
//           .where('userId', isEqualTo: currentUserId)
//           .where('type', isEqualTo: 'inflow')
//           .where('category', isEqualTo: finalCategory)
//           .where('item', isEqualTo: itemName)
//           .where('status', isEqualTo: 'Completed')
//           .get();

//       int totalInflow = snapshot.docs
//           .fold(0, (sum, doc) => sum + (doc['quantity'] ?? 0) as int);

//       final outflowSnapshot = await FirebaseFirestore.instance
//           .collection('contributions')
//           .where('userId', isEqualTo: currentUserId)
//           .where('type', isEqualTo: 'outflow')
//           .where('category', isEqualTo: finalCategory)
//           .where('item', isEqualTo: itemName)
//           .where('status', isEqualTo: 'Completed')
//           .get();

//       int totalOutflow = outflowSnapshot.docs
//           .fold(0, (sum, doc) => sum + (doc['quantity'] ?? 0) as int);

//       // If editing an outflow, subtract the old quantity from totalOutflow
//       if (doc != null && oldType == "outflow") {
//         totalOutflow -= oldQty;
//       }

//       final int availableQty = totalInflow - totalOutflow;
//       if (availableQty <= 0) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("This item has no available stock.")),
//         );
//         return;
//       }

//       if (requestedQty > availableQty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content:
//                   Text("Quantity exceeds available stock ($availableQty).")),
//         );
//         return;
//       }
//     }

//     // --- Check inflow edits against existing outflows ---
//     if (type == "inflow" && doc != null) {
//       final outflowSnapshot = await FirebaseFirestore.instance
//           .collection('contributions')
//           .where('userId', isEqualTo: currentUserId)
//           .where('type', isEqualTo: 'outflow')
//           .where('category', isEqualTo: finalCategory)
//           .where('item', isEqualTo: itemName)
//           .where('status', isEqualTo: 'Completed')
//           .get();

//       int totalOutflow = outflowSnapshot.docs
//           .fold(0, (sum, doc) => sum + (doc['quantity'] ?? 0) as int);

//       if (requestedQty < totalOutflow) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(
//                   "Cannot reduce incoming quantity below existing outflows ($totalOutflow).")),
//         );
//         return;
//       }
//     }

//     final data = {
//       "userId": currentUserId,
//       "type": type,
//       "category": finalCategory,
//       "item": itemName,
//       "description": _descriptionController.text.trim(),
//       "quantity": requestedQty,
//       "status": "Pending",
//       "donorName": type == "inflow" ? _donorNameController.text.trim() : "",
//       "donorContact":
//           type == "inflow" ? _donorContactController.text.trim() : "",
//       "requesterName":
//           type == "outflow" ? _requesterNameController.text.trim() : "",
//       "requesterContact":
//           type == "outflow" ? _requesterContactController.text.trim() : "",
//       "timestamp": FieldValue.serverTimestamp(),
//     };

//     try {
//       if (doc == null) {
//         await FirebaseFirestore.instance.collection('contributions').add(data);
//       } else {
//         await doc.reference.update(data);
//       }
//       _clearFields();
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save contribution: $e")),
//       );
//     }
//   }

//   void _clearFields() {
//     _itemController.clear();
//     _descriptionController.clear();
//     _quantityController.clear();
//     _donorNameController.clear();
//     _donorContactController.clear();
//     _requesterNameController.clear();
//     _requesterContactController.clear();
//     _otherCategoryController.clear();
//     _type = "inflow";
//     _selectedCategory = "Funds";
//   }

//   void _showAddOrEditDialog({DocumentSnapshot? doc}) {
//     String localType = doc != null ? doc['type'] ?? "inflow" : "inflow";
//     String localCategory = doc != null ? doc['category'] ?? "Funds" : "Funds";

//     if (doc != null && localCategory == "Other") {
//       _otherCategoryController.text = doc['category'] ?? "";
//     }

//     if (doc != null) {
//       _itemController.text = doc['item'] ?? "";
//       _descriptionController.text = doc['description'] ?? "";
//       _quantityController.text = "${doc['quantity'] ?? ""}";
//       _donorNameController.text = doc['donorName'] ?? "";
//       _donorContactController.text = doc['donorContact'] ?? "";
//       _requesterNameController.text = doc['requesterName'] ?? "";
//       _requesterContactController.text = doc['requesterContact'] ?? "";
//     }

//     showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setStateInDialog) {
//           return StreamBuilder<QuerySnapshot>(
//             stream: _fetchContributions(),
//             builder: (context, snapshot) {
//               final allContributions = snapshot.data?.docs ?? [];
//               Map<String, int> availableItems = {};
//               if (localType == "outflow") {
//                 availableItems =
//                     _getAvailableItems(allContributions, localCategory);
//                 if (_itemController.text.isEmpty && availableItems.isNotEmpty) {
//                   _itemController.text = availableItems.keys.first;
//                 }
//               }

//               return AlertDialog(
//                 title: Text(
//                   doc == null ? "Add Contribution" : "Edit Contribution",
//                   style: kTitleTextStyle.copyWith(fontSize: 15),
//                 ),
//                 content: Form(
//                   key: _formKey,
//                   child: SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Type
//                         DropdownButtonFormField<String>(
//                           value: localType,
//                           items: const [
//                             DropdownMenuItem(
//                                 value: "inflow",
//                                 child: Text("Incoming Donation")),
//                             DropdownMenuItem(
//                                 value: "outflow",
//                                 child: Text("Outgoing Donation")),
//                           ],
//                           onChanged: (val) {
//                             setStateInDialog(() {
//                               localType = val!;
//                             });
//                           },
//                           decoration: const InputDecoration(
//                               labelText: "Contribution Type"),
//                         ),
//                         // Category
//                         DropdownButtonFormField<String>(
//                           value: localCategory,
//                           items: _categories
//                               .map((c) =>
//                                   DropdownMenuItem(value: c, child: Text(c)))
//                               .toList(),
//                           onChanged: (val) {
//                             setStateInDialog(() {
//                               localCategory = val!;
//                               _itemController.clear();
//                             });
//                           },
//                           decoration:
//                               const InputDecoration(labelText: "Category"),
//                         ),
//                         // Other Category
//                         if (localCategory == "Other")
//                           TextFormField(
//                             controller: _otherCategoryController,
//                             decoration: const InputDecoration(
//                                 labelText: "Other Category"),
//                             validator: (value) {
//                               if (localCategory == "Other" &&
//                                   (value == null || value.isEmpty)) {
//                                 return "Please enter a category";
//                               }
//                               return null;
//                             },
//                           ),
//                         // Item
//                         if (localType == "outflow")
//                           DropdownButtonFormField<String>(
//                             value: _itemController.text.isNotEmpty
//                                 ? _itemController.text
//                                 : null,
//                             items: availableItems.keys
//                                 .map((item) => DropdownMenuItem(
//                                       value: item,
//                                       child: Text(
//                                           "$item (${availableItems[item]}) available"),
//                                     ))
//                                 .toList(),
//                             onChanged: (val) {
//                               setStateInDialog(() {
//                                 _itemController.text = val ?? "";
//                               });
//                             },
//                             decoration:
//                                 const InputDecoration(labelText: "Item"),
//                             validator: (val) {
//                               if (val == null || val.isEmpty) {
//                                 return "Please select an item";
//                               }
//                               return null;
//                             },
//                           )
//                         else
//                           TextFormField(
//                             controller: _itemController,
//                             decoration:
//                                 const InputDecoration(labelText: "Item Name"),
//                             validator: (value) => value == null || value.isEmpty
//                                 ? "Please enter item name"
//                                 : null,
//                           ),
//                         // Description
//                         TextFormField(
//                           controller: _descriptionController,
//                           decoration:
//                               const InputDecoration(labelText: "Description"),
//                         ),
//                         // Quantity
//                         TextFormField(
//                           controller: _quantityController,
//                           decoration:
//                               const InputDecoration(labelText: "Quantity"),
//                           keyboardType: TextInputType.number,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Please enter quantity";
//                             }
//                             final enteredQty = int.tryParse(value) ?? 0;
//                             if (enteredQty <= 0)
//                               return "Quantity must be greater than 0";
//                             if (localType == "outflow") {
//                               final maxQty =
//                                   availableItems[_itemController.text] ?? 0;
//                               if (enteredQty > maxQty) {
//                                 return "Cannot exceed available stock ($maxQty)";
//                               }
//                             }
//                             return null;
//                           },
//                         ),
//                         // Donor (inflow)
//                         if (localType == "inflow") ...[
//                           TextFormField(
//                             controller: _donorNameController,
//                             decoration:
//                                 const InputDecoration(labelText: "Donor Name"),
//                           ),
//                           TextFormField(
//                             controller: _donorContactController,
//                             decoration: const InputDecoration(
//                                 labelText: "Donor Contact"),
//                           ),
//                         ],
//                         // Requester (outflow)
//                         if (localType == "outflow") ...[
//                           TextFormField(
//                             controller: _requesterNameController,
//                             decoration: const InputDecoration(
//                                 labelText: "Requester Name"),
//                           ),
//                           TextFormField(
//                             controller: _requesterContactController,
//                             decoration: const InputDecoration(
//                                 labelText: "Requester Contact"),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _clearFields();
//                       },
//                       child: const Text("Cancel")),
//                   TextButton(
//                     onPressed: () {
//                       _addOrEditContribution(
//                         doc: doc,
//                         type: localType,
//                         category: localCategory,
//                       );
//                     },
//                     child: const Text("Save"),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Map<String, Map<String, dynamic>> _buildCategoryItemSummary(
//       List<QueryDocumentSnapshot> docs) {
//     final summary = <String, Map<String, dynamic>>{};

//     for (var doc in docs) {
//       final status = doc['status'] ?? "Pending";
//       if (status != "Completed") continue; // only completed

//       final category = doc['category'] ?? "Unknown";
//       final item = doc['item'] ?? "Unknown";
//       final qty = (doc['quantity'] ?? 0) as int;
//       final type = doc['type'] ?? "inflow";

//       summary.putIfAbsent(
//           category,
//           () => {
//                 "items": <String, int>{},
//                 "total": 0,
//               });

//       final items = summary[category]!["items"] as Map<String, int>;

//       if (type == "inflow") {
//         items[item] = (items[item] ?? 0) + qty;
//       } else if (type == "outflow") {
//         items[item] = (items[item] ?? 0) - qty;
//       }
//     }

//     // After processing all docs, compute totals per category and clamp items to 0
//     summary.forEach((category, data) {
//       final items = data["items"] as Map<String, int>;
//       int categoryTotal = 0;
//       items.forEach((item, qty) {
//         items[item] = max(0, qty);
//         categoryTotal += items[item]!;
//       });
//       data["total"] = categoryTotal;
//     });

//     return summary;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           buildSearchBar(
//             controller: _searchController,
//             hintText: "Search by item, category or status",
//             onChanged: (val) {
//               setState(() {
//                 _searchQuery = val.trim();
//               });
//             },
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _fetchContributions(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(
//                       child: Text(
//                     "Something went wrong: ${snapshot.error}",
//                     style: kSubtitleTextStyle,
//                   ));
//                 }

//                 final allContributions = snapshot.data!.docs;
//                 final filteredData = allContributions
//                     .where((doc) => _matchesSearch(doc, _searchQuery))
//                     .toList();

//                 final summary = _buildCategoryItemSummary(filteredData);

//                 if (filteredData.isEmpty) {
//                   return Center(
//                       child: Text(
//                     "No contributions found",
//                     style: kSubtitleTextStyle,
//                   ));
//                 }

//                 return SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       buildStyledCard(
//                         margin: const EdgeInsets.symmetric(horizontal: 12),
//                         child: ExpansionTile(
//                           tilePadding: EdgeInsets.zero,
//                           childrenPadding: EdgeInsets.zero,
//                           title: Text("Summary", style: kTitleTextStyle),
//                           children: [
//                             vSpace(2),
//                             ...summary.entries.map((catEntry) {
//                               final category = catEntry.key;
//                               final total = catEntry.value["total"] as int;
//                               final items =
//                                   catEntry.value["items"] as Map<String, int>;

//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 8.0),
//                                 child: ExpansionTile(
//                                   tilePadding: EdgeInsets.zero,
//                                   childrenPadding: EdgeInsets.zero,
//                                   title: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           category,
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       buildGreenChip("Total: $total"),
//                                     ],
//                                   ),
//                                   children: [
//                                     if (items.isNotEmpty)
//                                       Table(
//                                         columnWidths: const {
//                                           0: FlexColumnWidth(3),
//                                           1: FlexColumnWidth(1),
//                                         },
//                                         border: TableBorder(
//                                           horizontalInside: BorderSide(
//                                             width: 0.5,
//                                             color: Colors.grey.shade300,
//                                           ),
//                                         ),
//                                         children: [
//                                           TableRow(
//                                             decoration: BoxDecoration(
//                                                 color: Colors.grey.shade100),
//                                             children: const [
//                                               Padding(
//                                                 padding: EdgeInsets.all(4.0),
//                                                 child: Text(
//                                                   "Item",
//                                                   style: TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 14),
//                                                 ),
//                                               ),
//                                               Padding(
//                                                 padding: EdgeInsets.all(4.0),
//                                                 child: Text(
//                                                   "Qty",
//                                                   style: TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 14),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           ...items.entries.map(
//                                             (itemEntry) => TableRow(
//                                               children: [
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.all(4.0),
//                                                   child: Text(itemEntry.key,
//                                                       style: kSubtitleTextStyle
//                                                           .copyWith(
//                                                               fontSize: 15)),
//                                                 ),
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.all(4.0),
//                                                   child: Text(
//                                                       "${itemEntry.value}",
//                                                       style: kSubtitleTextStyle
//                                                           .copyWith(
//                                                               fontSize: 15)),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ],
//                         ),
//                       ),
//                       vSpace(10),
//                       ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: filteredData.length,
//                         itemBuilder: (context, index) {
//                           final contribution = filteredData[index];
//                           final type = contribution['type'] ?? "inflow";
//                           final category = contribution['category'] ?? "";
//                           final item = contribution['item'] ?? "Unknown";
//                           final desc = contribution['description'] ?? "";
//                           final quantity = contribution['quantity'] ?? 0;
//                           final status = contribution['status'] ?? "Pending";
//                           final donorName = contribution['donorName'] ?? "";
//                           final donorContact =
//                               contribution['donorContact'] ?? "";
//                           final requesterName =
//                               contribution['requesterName'] ?? "";
//                           final requesterContact =
//                               contribution['requesterContact'] ?? "";
//                           return Center(
//                             child: FractionallySizedBox(
//                               widthFactor: 0.9,
//                               child: buildWhiteCard(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 12, vertical: 8),
//                                 margin: const EdgeInsets.symmetric(vertical: 4),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(
//                                           category,
//                                           style: kTitleTextStyle.copyWith(
//                                               fontSize: 15),
//                                         ),
//                                         Chip(
//                                             label: Text(
//                                               type == "inflow"
//                                                   ? "Inflow"
//                                                   : "Outgoing",
//                                               style: const TextStyle(
//                                                   color: Colors.black),
//                                             ),
//                                             backgroundColor: type == "inflow"
//                                                 ? hexToColor("#a3ab94")
//                                                 : hexToColor("#e5ba9f")),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text("Item: $item ($quantity)",
//                                         style: kSubtitleTextStyle.copyWith(
//                                             fontSize: 15)),
//                                     if (desc.isNotEmpty)
//                                       Text("Description: $desc",
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15)),
//                                     Text("Status: $status",
//                                         style: kSubtitleTextStyle.copyWith(
//                                             fontSize: 15)),
//                                     if (type == "inflow" &&
//                                         donorName.isNotEmpty) ...[
//                                       Text("Donor Name: $donorName",
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15)),
//                                       Text(
//                                           "Donor Contact: ${donorContact.isNotEmpty ? donorContact : '-'}",
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15)),
//                                     ],
//                                     if (type == "outflow" &&
//                                         requesterName.isNotEmpty) ...[
//                                       Text("Recipient Name: $requesterName",
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15)),
//                                       Text(
//                                           "Recipient Contact: ${requesterContact.isNotEmpty ? requesterContact : '-'}",
//                                           style: kSubtitleTextStyle.copyWith(
//                                               fontSize: 15)),
//                                     ],
//                                     Align(
//                                       alignment: Alignment.centerRight,
//                                       child: PopupMenuButton<String>(
//                                         onSelected: (value) async {
//                                           try {
//                                             if (value == "markCompleted") {
//                                               await contribution.reference
//                                                   .update(
//                                                       {"status": "Completed"});
//                                             } else if (value == "markPending") {
//                                               await contribution.reference
//                                                   .update(
//                                                       {"status": "Pending"});
//                                             } else if (value == "edit") {
//                                               _clearFields();
//                                               _showAddOrEditDialog(
//                                                   doc: contribution);
//                                             }
//                                           } catch (e) {
//                                             ScaffoldMessenger.of(context)
//                                                 .showSnackBar(
//                                               SnackBar(
//                                                   content: Text(
//                                                       "Action failed: $e")),
//                                             );
//                                           }
//                                         },
//                                         itemBuilder: (context) => [
//                                           if (status != "Completed")
//                                             const PopupMenuItem(
//                                               value: "markCompleted",
//                                               child: Text("Mark as Completed"),
//                                             ),
//                                           if (status != "Pending")
//                                             const PopupMenuItem(
//                                               value: "markPending",
//                                               child: Text("Mark as Pending"),
//                                             ),
//                                           const PopupMenuItem(
//                                             value: "edit",
//                                             child: Text("Edit"),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       vSpace(10),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: hexToColor("#a3ab94"),
//         onPressed: () {
//           _clearFields();
//           _showAddOrEditDialog();
//         },
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
// }
