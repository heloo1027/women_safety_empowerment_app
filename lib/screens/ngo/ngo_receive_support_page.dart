// pending
import 'package:flutter/material.dart';

class NGOReceiveSupportPage extends StatelessWidget {
  const NGOReceiveSupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with Firestore StreamBuilder
    final dummyRequests = [
      {"beneficiary": "Maria", "need": "Sanitary Pads"},
      {"beneficiary": "Rani", "need": "Groceries"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Beneficiary Requests")),
      body: ListView.builder(
        itemCount: dummyRequests.length,
        itemBuilder: (context, index) {
          final req = dummyRequests[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: Text(req["beneficiary"] ?? ""),
              subtitle: Text("Needs: ${req["need"]}"),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Connect via chat or mark as supported
                },
                child: const Text("Respond"),
              ),
            ),
          );
        },
      ),
    );
  }
}
