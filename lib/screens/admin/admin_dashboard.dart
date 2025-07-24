import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:flutter_application_1/screens/employee/bill_viewer_page.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  final String userId;
  final String email;

  const AdminDashboard({super.key, required this.userId, required this.email});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allBills = [];
  bool isLoading = true;
  String? errorMessage;

  Map<String, String> userNames = {};

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

      final usersData = await supabase.from('users').select('id, username');
      userNames = {
        for (var user in usersData)
          user['id'] as String: user['username'] as String,
      };

      final billsResponse = await supabase
          .from('bills')
          .select(
            'id, user_id, purpose, amount, date, status, image_url, source, invoice_no, description, created_at, admin_notes',
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

  Future<void> _updateBillStatusWithRemarks(
    String billId,
    String newStatus,
  ) async {
    final TextEditingController remarksController = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Remarks for ${newStatus.toUpperCase()}'),
          content: TextField(
            controller: remarksController,
            decoration: const InputDecoration(hintText: "Optional remarks"),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performStatusUpdate(
                  billId,
                  newStatus,
                  remarksController.text,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performStatusUpdate(
    String billId,
    String newStatus,
    String remarks,
  ) async {
    setState(() {
      isLoading = true;
    });
    try {
      final dbResponse = await supabase
          .from('bills')
          .update({'status': newStatus, 'admin_notes': remarks})
          .eq('id', billId);

      if (dbResponse == null) {
        print(
          'DEBUG: DB Update returned null response but no error was thrown. Assuming success.',
        );
      } else if (dbResponse.error != null) {
        print(
          'DEBUG: DB Update returned non-null response with error: ${dbResponse.error!.message}',
        );
        throw dbResponse.error!;
      } else {
        print('DEBUG: DB Update returned successful response.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill $newStatus successfully!')),
        );
      }
      _checkAdminRoleAndFetchBills();
    } catch (e) {
      print("Error updating bill status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}')),
        );
      }
      setState(() {
        isLoading = false;
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
      default:
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
                final String personUsername =
                    userNames[bill['user_id']] ?? 'Unknown User';

                String formattedClaimDate = 'N/A';
                if (bill['created_at'] != null) {
                  try {
                    final DateTime parsedCreatedAt = DateTime.parse(
                      bill['created_at'],
                    );
                    formattedClaimDate = DateFormat(
                      'MMM dd, yyyy',
                    ).format(parsedCreatedAt);
                  } catch (e) {
                    print("Error parsing created_at for admin display: $e");
                    formattedClaimDate = bill['created_at'].toString().split(
                      'T',
                    )[0];
                  }
                }

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
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                personUsername, // Display Username
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₹${(bill['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A'}', // CHANGED: '$' to '₹'
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill['description'] ?? 'No Description',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Claimed: $formattedClaimDate | Source: ${bill['source'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
                                  builder: (context) => BillViewerPage(
                                    billData: bill,
                                    isAdmin: true,
                                  ),
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
                              bill['status'] == 'pending'
                                  ? Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _updateBillStatusWithRemarks(
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
                                          onPressed: () =>
                                              _updateBillStatusWithRemarks(
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
                                      'Status: ${bill['status']?.toUpperCase() ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            bill['status']?.toLowerCase() ==
                                                'approved'
                                            ? Colors.green
                                            : Colors.red, // Corrected typo here
                                      ),
                                    ),
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
