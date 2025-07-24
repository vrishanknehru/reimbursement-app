import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/take_img.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:flutter_application_1/screens/employee/bill_viewer_page.dart';
import 'package:intl/intl.dart';

class EmployeeHome extends StatefulWidget {
  final String userId;
  final String email;

  const EmployeeHome({super.key, required this.userId, required this.email});

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
    _checkUserAndFetchBills();
  }

  Future<void> _checkUserAndFetchBills() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userResponse = await supabase
          .from('users')
          .select('id, role')
          .eq('id', widget.userId)
          .eq('email', widget.email)
          .maybeSingle();

      if (userResponse == null ||
          userResponse['role']?.toString().toLowerCase() != 'employee') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Authentication/Role invalid. Please log in again.",
              ),
            ),
          );
          _navigateToLogin();
        }
        return;
      }

      final userId = userResponse['id'] as String;

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

  void _navigateToLogin() async {
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
              onPressed: _checkUserAndFetchBills,
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

                String formattedDate = 'N/A';
                if (entry['created_at'] != null) {
                  try {
                    final DateTime parsedCreatedAt = DateTime.parse(
                      entry['created_at'],
                    );
                    formattedDate = DateFormat(
                      'MMM dd, yyyy',
                    ).format(parsedCreatedAt);
                  } catch (e) {
                    print("Error parsing created_at for display: $e");
                    formattedDate = entry['created_at'].toString().split(
                      'T',
                    )[0];
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          entry['description'] ?? 'No Description',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${entry['purpose'] ?? 'N/A Purpose'} | ${entry['source'] ?? 'N/A Source'}",
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          "Amount: ₹${(entry['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A'} | Invoice: ${entry['invoice_no'] ?? 'N/A'}", // CHANGED: '$' to '₹'
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: _buildStatusIcon(
                      entry['status']?.toString() ?? 'processing',
                    ),
                    onTap: () {
                      final billUrl = entry['image_url'];
                      if (billUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BillViewerPage(billData: entry),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No bill image/PDF found for this entry.",
                            ),
                          ),
                        );
                      }
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
                    builder: (context) =>
                        HistoryPage(userId: widget.userId, email: widget.email),
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
              builder: (context) =>
                  TakeImagePage(userId: widget.userId, userEmail: widget.email),
            ),
          );
          _checkUserAndFetchBills();
        },
        tooltip: 'Add New Bill',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
