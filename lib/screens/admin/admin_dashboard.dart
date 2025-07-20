import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For logout (optional)

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut(); // Optional: clear session
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context), // Calls logout method
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Admin!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
