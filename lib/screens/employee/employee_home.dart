import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/take_img.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/login_page.dart';
// REMOVED: import 'package:flutter_application_1/screens/employee/bill_viewer_page.dart';

class EmployeeHome extends StatefulWidget {
  final String email;

  const EmployeeHome({super.key, required this.email});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> userBills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRoleAndFetchBills();
  }

  Future<void> _checkRoleAndFetchBills() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userResponse = await supabase
          .from('users')
          .select('id, role')
          .eq('email', widget.email)
          .maybeSingle();

      if (userResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User not found. Please log in again."),
            ),
          );
          _navigateToLogin();
        }
        return;
      }

      final userId = userResponse['id'] as String;
      final role = userResponse['role']?.toString().toLowerCase();

      if (role != 'employee') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Access Denied: Your role is '$role', not an employee.",
              ),
            ),
          );
          _navigateToLogin();
        }
        return;
      }

      // Ensure 'image_url' is selected (even if not used for direct viewing on this page, it's in DB)
      final billsResponse = await supabase
          .from('bills')
          .select(
            'purpose, source, amount, date, invoice_no, description, status, created_at, image_url',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        userBills = List<Map<String, dynamic>>.from(billsResponse);
        isLoading = false;
      });
    } catch (e) {
      print("Error in EmployeeHome: $e");
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load data: ${e.toString()}")),
        );
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
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
        title: Row(
          children: [
            const Text("Home"),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkRoleAndFetchBills,
              tooltip: 'Refresh',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _navigateToLogin,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      "${entry['purpose'] ?? 'N/A'} - ${entry['source'] ?? 'N/A'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date: ${entry['date'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Invoice: ${entry['invoice_no'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Amount: \$${(entry['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Desc: ${entry['description'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: _buildStatusIcon(
                      entry['status']?.toString() ?? 'processing',
                    ),
                    onTap: () {
                      // This was the state before BillViewerPage: simple SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Tapped on bill. Bill viewer not implemented.",
                          ),
                        ),
                      );
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
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(email: widget.email),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakeImagePage(userEmail: widget.email),
            ),
          );
          _checkRoleAndFetchBills();
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Bill',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
