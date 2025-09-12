import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // final _formKey = GlobalKey<FormState>();

  // Dropdown + Text Controllers
  // For "Donate to Us"
  String? _donateCategory;
  String? _donateItem;
  final TextEditingController _donateQuantityController =
      TextEditingController();
  final TextEditingController _donateDescriptionController =
      TextEditingController();

// For "Need Our Help"
  String? _helpCategory;
  String? _helpItem;
  final TextEditingController _helpQuantityController = TextEditingController();
  final TextEditingController _helpDescriptionController =
      TextEditingController();

  // For "Donate to Us"
  Future<void> _submitRequest(List<DocumentSnapshot> reqs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_donateCategory == null || _donateItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select category and item")),
      );
      return;
    }

    final qty = int.tryParse(_donateQuantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid quantity")),
      );
      return;
    }

    // ✅ find existing NGO request
    DocumentSnapshot? req;
    try {
      req = reqs.firstWhere(
        (d) => d['item'] == _donateItem && d['category'] == _donateCategory,
      );
    } catch (e) {
      req = null;
    }

    if (req != null) {
      final reqId = req.id;
      final reqData = req.data() as Map<String, dynamic>;
      final totalQty = reqData['quantity'] ?? 0;
      final fulfilledQty = reqData['fulfilledQuantity'] ?? 0;

      // ✅ Check if donation would exceed target
      if (fulfilledQty + qty > totalQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "This request only needs ${totalQty - fulfilledQty} more items."),
          ),
        );
        return;
      }

      final ngoRef =
          FirebaseFirestore.instance.collection('contributions').doc(reqId);

      // Just record the donation, no updates yet
      await ngoRef.collection('donations').add({
        'womanId': user.uid,
        // 'womanName': user.displayName,
        'quantity': qty,
        'description': _donateDescriptionController.text.trim(),
        'status': 'Pending', // waiting NGO approval
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Donation submitted, pending NGO approval")),
      );
    }

    // reset form
    _donateQuantityController.clear();
    _donateDescriptionController.clear();
    setState(() {
      _donateCategory = null;
      _donateItem = null;
    });
  }

// For "Need Our Help"
Future<void> _submitNGOHelpRequest(List<DocumentSnapshot> completedReqs) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (_helpCategory == null || _helpItem == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select category and item")),
    );
    return;
  }

  final qty = int.tryParse(_helpQuantityController.text.trim());
  if (qty == null || qty <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter valid quantity")),
    );
    return;
  }

  // Find the completed NGO request
  DocumentSnapshot? req;
  try {
    req = completedReqs.firstWhere(
      (d) => d['item'] == _helpItem && d['category'] == _helpCategory,
    );
  } catch (e) {
    req = null;
  }

  if (req == null) return;

  final reqRef = FirebaseFirestore.instance.collection('contributions').doc(req.id);

  // Fetch latest snapshot to ensure we have up-to-date availableQuantity
  final freshData = await reqRef.get();
  final reqData = freshData.data() as Map<String, dynamic>;

  // If availableQuantity doesn't exist, initialize it to quantity
  int availableQty = reqData['availableQuantity'] ?? reqData['quantity'] ?? 0;
  if (!reqData.containsKey('availableQuantity')) {
    await reqRef.update({'availableQuantity': availableQty});
  }

  if (qty > availableQty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You can request up to $availableQty items only."),
      ),
    );
    return;
  }

  // Save request under NGO's contributions (subcollection)
  await reqRef.collection('requestsFromWomen').add({
    'womanId': user.uid,
    // 'womanName': user.displayName,
    'quantity': qty,
    'description': _helpDescriptionController.text.trim(),
    'status': 'Pending',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Decrement availableQuantity
  // await reqRef.update({'availableQuantity': FieldValue.increment(-qty)});

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Request submitted, awaiting NGO approval")),
  );

  // Reset form
  _helpQuantityController.clear();
  _helpDescriptionController.clear();
  setState(() {
    _helpCategory = null;
    _helpItem = null;
  });
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
                    widget.name, style: kTitleTextStyle,
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
                      style: const TextStyle(fontSize: 15), textAlign: TextAlign.justify,),
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
              child:  Text(
                "Donate to us",
                style: kTitleTextStyle,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
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
                  .collection('contributions')
                  .where('ngoId', isEqualTo: widget.ngoId)
                  .where('type', isEqualTo: 'ngoRequest')
                  .where('status',
                      whereIn: ['Open', 'In Progress']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reqs = snapshot.data!.docs;

                if (reqs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child:  Text("This NGO currently has no open requests."),
                  );
                }

                // final categories =
                //     reqs.map((d) => d['category'] as String).toSet().toList();
                // final items =
                //     reqs.map((d) => d['item'] as String).toSet().toList();

                final categories =
                    reqs.map((d) => d['category'] as String).toSet().toList();

                final items = _donateCategory == null
                    ? []
                    : reqs
                        .where((d) => d['category'] == _donateCategory)
                        .map((d) => d['item'] as String)
                        .toSet()
                        .toList();

// Quantity input with max display
                int getAvailableQtyForSelectedDonationItem() {
                  if (_donateCategory == null || _donateItem == null) return 0;

                  try {
                    final req = reqs.firstWhere((d) =>
                        d['category'] == _donateCategory &&
                        d['item'] == _donateItem);
                    final data = req.data() as Map<String, dynamic>;
                    final totalQty = data['quantity'] ?? 0;
                    final fulfilledQty = data['fulfilledQuantity'] ?? 0;
                    return totalQty - fulfilledQty; // remaining quantity
                  } catch (_) {
                    return 0;
                  }
                }

                final availableDonationQty =
                    getAvailableQtyForSelectedDonationItem();

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _donateCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _donateCategory = val;
                              _donateItem =
                                  null; // 👈 reset item when category changes
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Item dropdown
                        DropdownButtonFormField<String>(
                          value: _donateItem,
                          decoration: const InputDecoration(
                            labelText: "Item",
                            border: OutlineInputBorder(),
                          ),
                          items: items.map((itm) {
                            final itemStr = itm.toString(); // force to String
                            return DropdownMenuItem<String>(
                              value: itemStr,
                              child: Text(itemStr),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _donateItem = val;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Quantity input
                        TextFormField(
                          controller: _donateQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Quantity (max $availableDonationQty)",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _donateDescriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Description (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit button
                        ElevatedButton(
                          onPressed: () {
                            _submitRequest(reqs);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hexToColor("#a3ab94"),
                          ),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // ------------------ Need Our Help Section ------------------
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 7.0),
              child:  Text(
                "Need Our Help",
                style: kTitleTextStyle,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: const Text(
                "Request avaiable items from us",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contributions')
                  .where('ngoId', isEqualTo: widget.ngoId)
                  .where('type', isEqualTo: 'ngoRequest')
                  .where('status', isEqualTo: 'Completed')
                  .where('availableQuantity', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final completedReqs = snapshot.data!.docs;

                if (completedReqs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text("No items available to request."),
                  );
                }

                // Ensure all documents have availableQuantity
                for (var doc in completedReqs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (!data.containsKey('availableQuantity')) {
                    FirebaseFirestore.instance
                        .collection('contributions')
                        .doc(doc.id)
                        .update({'availableQuantity': data['quantity'] ?? 0});
                  }
                }

                final availableReqs =
                    completedReqs.toList(); // show all completed

                final categories = availableReqs
                    .map((d) => (d.data() as Map<String, dynamic>)['category']
                        as String)
                    .toSet()
                    .toList();

                final items = _helpCategory == null
                    ? []
                    : availableReqs
                        .where((d) =>
                            (d.data() as Map<String, dynamic>)['category'] ==
                            _helpCategory)
                        .map((d) => (d.data() as Map<String, dynamic>)['item']
                            as String)
                        .toSet()
                        .toList();

                int getAvailableQtyForSelectedItem() {
                  if (_helpCategory == null || _helpItem == null) return 0;
                  try {
                    final req = availableReqs.firstWhere((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['category'] == _helpCategory &&
                          data['item'] == _helpItem;
                    });
                    final data = req.data() as Map<String, dynamic>;
                    return (data['availableQuantity'] ?? data['quantity'] ?? 0);
                  } catch (_) {
                    return 0;
                  }
                }

                final availableQty = getAvailableQtyForSelectedItem();

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: _helpCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _helpCategory = val;
                              _helpItem = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Item dropdown
                        DropdownButtonFormField<String>(
                          value: _helpItem,
                          decoration: const InputDecoration(
                            labelText: "Item",
                            border: OutlineInputBorder(),
                          ),
                          items: items.map((itm) {
                            return DropdownMenuItem<String>(
                              value: itm,
                              child: Text(itm),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _helpItem = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Quantity input
                        TextFormField(
                          controller: _helpQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Quantity (max $availableQty)",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _helpDescriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Description (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit button
                        ElevatedButton(
                          onPressed: availableQty > 0
                              ? () => _submitNGOHelpRequest(availableReqs)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hexToColor("#a3ab94"),
                          ),
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
