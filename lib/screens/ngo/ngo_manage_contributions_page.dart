import 'package:flutter/material.dart';

class NGOManageContributionsPage extends StatelessWidget {
  const NGOManageContributionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with Firestore StreamBuilder
    final dummyData = [
      {"donor": "Alice", "item": "Clothes", "status": "Delivered"},
      {"donor": "Bob", "item": "Funds", "status": "Pending"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Contributions")),
      body: ListView.builder(
        itemCount: dummyData.length,
        itemBuilder: (context, index) {
          final item = dummyData[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.volunteer_activism, color: Colors.green),
              title: Text("${item["donor"]} donated ${item["item"]}"),
              subtitle: Text("Status: ${item["status"]}"),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Update contribution status in Firestore
                },
                child: const Text("Update"),
              ),
            ),
          );
        },
      ),
    );
  }
}
