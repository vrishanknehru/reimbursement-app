import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/take_img.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  
  Widget _buildStatusIcon(String status) {
    if (status == 'approved') {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (status == 'rejected') {
      return const Icon(Icons.cancel, color: Colors.red);
    } else {
     
      return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('userBox');
    List entries = box.get('entries', defaultValue: []);

    
    List recentEntries = entries.reversed.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Text("Home"), const Spacer()]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: recentEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "No bill uploaded yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Status: N/A",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: recentEntries.length,
              itemBuilder: (context, index) {
                final entry = recentEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      "${entry['purpose']} - ${entry['source']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date: ${entry['date'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Invoice: ${entry['invoiceNumber'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Amount: ${entry['amount'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Desc: ${entry['description'] ?? ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: _buildStatusIcon(entry['status'] ?? 'processing'),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: () async {
                var box = Hive.box('userBox');
                await box.clear();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All local entries cleared!')),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TakeImagePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
