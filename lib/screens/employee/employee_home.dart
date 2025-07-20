import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/take_img.dart';
import 'package:flutter_application_1/screens/employee/history_page.dart'; // Ensure this exists if you use it
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeHome extends StatefulWidget {
  final String email; // Back to using email
  const EmployeeHome({super.key, required this.email});

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
    // Note: Realtime might not work as intended without RLS or specific channel setup
    // for this custom authentication approach.
  }

  Future<void> _fetchBills() async {
    setState(() {
      isLoading = true;
      errorMessage = null; // Clear previous errors
    });
    try {
      // First, get the user's ID from your 'users' table using their email
      final userResponse = await supabase
          .from('users') // Querying your custom 'users' table
          .select('id')
          .eq('email', widget.email)
          .maybeSingle();

      if (userResponse == null || userResponse['id'] == null) {
        setState(() {
          errorMessage = "User ID not found for this email.";
          isLoading = false;
        });
        return;
      }

      final userId = userResponse['id'];

      // Then, fetch bills using that custom user ID
      final bills = await supabase
          .from('bills')
          .select()
          .eq('user_id', userId) // Assuming 'bills' table still has a 'user_id'
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        userBills = List<Map<String, dynamic>>.from(bills);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch bills: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Widget _buildStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default: // For 'pending' or any other status
        return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // No Supabase Auth signOut here, just navigate back
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false, // Remove all previous routes
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBills),
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No bills found. Start by adding one!"),
                  SizedBox(height: 20),
                  Icon(Icons.add_circle_outline, size: 50, color: Colors.grey),
                ],
              ),
            )
          : ListView.builder(
              itemCount: userBills.length,
              itemBuilder: (context, index) {
                final entry = userBills[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: _buildStatusIcon(entry['status']),
                    title: Text(
                      entry['purpose'] != null && entry['source'] != null
                          ? "${entry['purpose']} - ${entry['source']}"
                          : "Reimbursement Request",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Amount: ${entry['amount'] ?? 'N/A'}"),
                        Text("Date: ${entry['date'] ?? 'N/A'}"),
                        Text("Status: ${entry['status'] ?? 'N/A'}"),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to a detailed bill view page
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TakeImagePage()),
          );
          _fetchBills(); // Refresh after potentially adding a new bill
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
