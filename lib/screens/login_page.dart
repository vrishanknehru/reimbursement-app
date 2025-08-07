import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'employee/employee_home.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  final supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Select 'username' in addition to 'id' and 'role'
      final response = await supabase
          .from('users')
          .select('id, role, username') // NEW: Select username
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        setState(() {
          errorMessage = 'Invalid login credentials';
        });
        return;
      }

      final userId = response['id'];
      final role = response['role']?.toString().toLowerCase();
      final username =
          response['username'] as String?; // Get username, can be null

      print(
        'LOGIN_DEBUG: Raw user ID from DB: $userId (Type: ${userId.runtimeType})',
      );
      if (userId == null || userId is! String || (userId).isEmpty) {
        setState(() {
          errorMessage =
              'User ID is missing, invalid, or empty from database. Please check DB.';
        });
        print('LOGIN_DEBUG: User ID from DB is null or not String, or empty.');
        return;
      }
      final String finalUserId = userId;
      print(
        'LOGIN_DEBUG: Final userId to pass from Login: "$finalUserId" (length: ${finalUserId.length})',
      );
      print('LOGIN_DEBUG: Username to pass: "$username"'); // Debug username

      _handleNavigation(
        role,
        finalUserId,
        email,
        username,
      ); // NEW: Pass username
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed. Please try again: ${e.toString()}';
      });
      print('LOGIN_DEBUG: Sign-in caught exception: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleNavigation(
    String? role,
    String userId,
    String email,
    String? username,
  ) {
    // NEW: Add username param
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AdminDashboard(userId: userId, email: email, username: username),
        ), // NEW: Pass username
      );
    } else if (role == 'employee') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmployeeHome(userId: userId, email: email, username: username),
        ), // NEW: Pass username
      );
    } else {
      setState(() {
        errorMessage = 'Unknown user role. Please contact support.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
               
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage.isNotEmpty)
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 10),
                      MaterialButton(
                        minWidth: double.infinity,
                        onPressed: isLoading ? null : _signIn,
                        color: Colors.black,
                        textColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
