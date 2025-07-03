import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart';
import 'package:flutter_application_1/screens/employee/purpose_page.dart';
// import 'package:flutter_application_1/screens/employee/';
// import 'employee/status_page.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
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

      body: Center(
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
      ),

      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>PurposePage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: () {
                // Status or another feature
              },
            ),
          ],
        ),
      ),
    );
  }
}
