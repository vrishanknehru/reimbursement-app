import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('userBox');
    List entries = box.get('entries', defaultValue: []);

    // Reverse to show latest first
    List allEntries = entries.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: allEntries.isEmpty
          ? const Center(
              child: Text("No entries yet", style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: allEntries.length,
              itemBuilder: (context, index) {
                final entry = allEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      "${entry['purpose']} - ${entry['source']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: ${entry['date'] ?? ''}", style: const TextStyle(fontSize: 12)),
                        Text("Invoice: ${entry['invoiceNumber'] ?? ''}", style: const TextStyle(fontSize: 12)),
                        Text("Amount: ${entry['amount'] ?? ''}", style: const TextStyle(fontSize: 12)),
                        Text("Desc: ${entry['description'] ?? ''}", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
