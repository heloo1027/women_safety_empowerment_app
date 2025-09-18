// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'ngo_chat_page.dart';
// import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

// // Page where NGO can view all support requests received from women
// class NGOReceiveSupportPage extends StatelessWidget {
//   const NGOReceiveSupportPage({Key? key}) : super(key: key);

//   // List of possible statuses for a request
//   final List<String> statusOptions = const [
//     "Pending",
//     "Waiting for Collection",
//     "Completed",
//     "Rejected"
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     // Show message if user is not logged in
//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text("Not logged in")),
//       );
//     }

//     return Scaffold(
//       // StreamBuilder listens for real-time updates of requests made to this NGO
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('womanRequests')
//             .where('ngoId',
//                 isEqualTo: currentUser.uid) // filter by logged-in NGO
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           // Show loading spinner while waiting for data
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           // Show message if there are no requests
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No requests yet."));
//           }

//           final requests = snapshot.data!.docs;

//           // Build a scrollable list of requests
//           return ListView.builder(
//             itemCount: requests.length,
//             itemBuilder: (context, index) {
//               final reqDoc = requests[index];
//               final reqData = reqDoc.data() as Map<String, dynamic>;
//               final requestId = reqDoc.id;
//               final womanId = reqData["womanId"];

//               // Fetch woman's profile info asynchronously
//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection('womanProfiles')
//                     .doc(womanId)
//                     .get(),
//                 builder: (context, womanSnapshot) {
//                   // Show nothing if data not yet loaded
//                   if (!womanSnapshot.hasData) {
//                     return const SizedBox.shrink(); // empty placeholder
//                   }

//                   final womanData =
//                       womanSnapshot.data!.data() as Map<String, dynamic>? ?? {};

//                   final womanName = womanData["name"] ?? "Unknown";
//                   final profileImage = womanData["profileImage"];
//                   final currentStatus = reqData["status"] ?? "Pending";

//                   // Card to display request details
//                   return Card(
//                     margin: const EdgeInsets.all(8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Image and Name
//                           Row(
//                             children: [
//                               CircleAvatar(
//                                 backgroundImage: profileImage != null
//                                     ? NetworkImage(profileImage)
//                                     : null,
//                                 child: profileImage == null
//                                     ? const Icon(Icons.person)
//                                     : null,
//                               ),
//                               const SizedBox(width: 12),
//                               Text(womanName, style: kTitleTextStyle),
//                             ],
//                           ),
//                           const SizedBox(height: 8),

//                           // Category, Item, Quantity, Description
//                           Text.rich(TextSpan(
//                             children: [
//                               const TextSpan(
//                                   text: "Category: ",
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                               TextSpan(text: "${reqData["category"] ?? "-"}"),
//                             ],
//                           )),
//                           Text.rich(TextSpan(
//                             children: [
//                               const TextSpan(
//                                   text: "Item: ",
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                               TextSpan(text: "${reqData["item"] ?? "-"}"),
//                             ],
//                           )),
//                           Text.rich(TextSpan(
//                             children: [
//                               const TextSpan(
//                                   text: "Quantity: ",
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                               TextSpan(text: "${reqData["quantity"] ?? "-"}"),
//                             ],
//                           )),
//                           Text.rich(TextSpan(
//                             children: [
//                               const TextSpan(
//                                   text: "Description: ",
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                               TextSpan(
//                                   text: "${reqData["description"] ?? "-"}"),
//                             ],
//                           )),

//                           // Status dropdown
//                           Row(
//                             children: [
//                               const Text("Status: ",
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                               const SizedBox(width: 8),
//                               Flexible(
//                                 child: DropdownButton<String>(
//                                   value: currentStatus,
//                                   isExpanded: true,
//                                   items: statusOptions
//                                       .map((status) => DropdownMenuItem(
//                                             value: status,
//                                             child: Text(status),
//                                           ))
//                                       .toList(),
//                                   onChanged: (newStatus) async {
//                                     if (newStatus != null) {
//                                       await FirebaseFirestore.instance
//                                           .collection('womanRequests')
//                                           .doc(requestId)
//                                           .update({"status": newStatus});
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),

//                           // Date and Chat button row
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "Requested on: ${((reqData["createdAt"] as Timestamp?)?.toDate() != null ? "${((reqData["createdAt"] as Timestamp).toDate().day).toString().padLeft(2, '0')}/${((reqData["createdAt"] as Timestamp).toDate().month).toString().padLeft(2, '0')}/${((reqData["createdAt"] as Timestamp).toDate().year.toString().substring(2))}" : "-")}",
//                                 style: kSmallTextStyle,
//                               ),
//                               ElevatedButton.icon(
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => NGOChatPage(
//                                           receiverId: womanId,
//                                           receiverName: womanName),
//                                     ),
//                                   );
//                                 },
//                                 icon: const Icon(Icons.chat, size: 16),
//                                 label: const Text("Chat"),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
