import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:flutter_application_1/screens/employee/bill_viewer_page.dart';

class AdminDashboard extends StatefulWidget {
  final String userId; // Admin's User ID from custom auth
  final String email; // Admin's email from custom auth

  const AdminDashboard({super.key, required this.userId, required this.email});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allBills = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminRoleAndFetchBills();
  }

  Future<void> _checkAdminRoleAndFetchBills() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Verify admin role from 'users' table using passed userId and email
      final userResponse = await supabase
          .from('users')
          .select('role')
          .eq('id', widget.userId)
          .eq('email', widget.email)
          .maybeSingle();

      if (userResponse == null ||
          userResponse['role']?.toString().toLowerCase() != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Access Denied: You are not an admin."),
            ),
          );
          _navigateToLogin();
        }
        return;
      }

      // Fetch all bills from the 'bills' table (admins can see all)
      // Including image_url for BillViewerPage
      final billsResponse = await supabase
          .from('bills')
          .select(
            'id, user_id, purpose, amount, date, status, image_url, source, invoice_no, description, created_at',
          )
          .order('created_at', ascending: false);

      setState(() {
        allBills = List<Map<String, dynamic>>.from(billsResponse);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching bills for admin: $e");
      setState(() {
        errorMessage = 'Failed to load bills: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _updateBillStatus(String billId, String newStatus) async {
    setState(() {
      isLoading = true; // Show loading while updating
    });
    try {
      final dbResponse = await supabase
          .from('bills')
          .update({'status': newStatus})
          .eq('id', billId);

      if (dbResponse.error != null) {
        throw dbResponse.error!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill $newStatus successfully!')),
        );
      }
      _checkAdminRoleAndFetchBills(); // Refresh list
    } catch (e) {
      print("Error updating bill status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}')),
        );
      }
      setState(() {
        isLoading = false; // Stop loading on error
      });
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
      default: // For 'pending', 'processing', etc.
        return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAdminRoleAndFetchBills,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _navigateToLogin,
            tooltip: 'Logout',
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
          : allBills.isEmpty
          ? const Center(child: Text("No bills submitted yet."))
          : ListView.builder(
              itemCount: allBills.length,
              itemBuilder: (context, index) {
                final bill = allBills[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            "${bill['purpose'] ?? 'N/A Purpose'} - \$${(bill['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${bill['date'] ?? 'N/A'}'),
                              Text(
                                'Status: ${bill['status']?.toUpperCase() ?? 'N/A'}',
                              ),
                              Text(
                                'Submitted by User ID: ${bill['user_id'] ?? 'N/A'}',
                              ),
                            ],
                          ),
                          trailing: _buildStatusIcon(
                            bill['status']?.toString() ?? 'processing',
                          ),
                          onTap: () {
                            final billUrl = bill['image_url'];
                            if (billUrl != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BillViewerPage(billData: bill),
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
                        // Approval/Rejection Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // --- FIX START ---
                              bill['status'] == 'pending'
                                  ? Row(
                                      // Wrap the two buttons in a Row
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _updateBillStatus(
                                            bill['id'],
                                            'approved',
                                          ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _updateBillStatus(
                                            bill['id'],
                                            'rejected',
                                          ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      // Just display status if not pending
                                      'Status: ${bill['status']?.toUpperCase() ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: bill['status'] == 'approved'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                              // --- FIX END ---
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
