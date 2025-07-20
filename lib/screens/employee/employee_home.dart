import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/take_img.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userBills = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "User not logged in";
      });
      return;
    }

    try {
      final response = await supabase
          .from('bills')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        userBills = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Text("Home"), const Spacer()]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : userBills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.description, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "No bill uploaded yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Status: N/A",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: userBills.length,
              itemBuilder: (context, index) {
                final entry = userBills[index];
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
                          "Invoice: ${entry['invoice'] ?? ''}",
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
                    onTap: () {
                      // Optional: preview image from entry['image_url']
                    },
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
