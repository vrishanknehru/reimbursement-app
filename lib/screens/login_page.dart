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

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle(); // Use maybeSingle to safely return null if no match

      print('Supabase login response: $response');

      if (response == null) {
        setState(() {
          errorMessage = 'Invalid login credentials';
        });
        return;
      }

      final role = response['role']?.toString().toLowerCase(); // Normalize role

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeHome()),
        );
      } else {
        setState(() {
          errorMessage = 'Unknown user role';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed. Please try again.';
      });
      print('Login error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(246, 255, 255, 255),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/clogo.png.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  child: Form(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.password),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MaterialButton(
                            minWidth: double.infinity,
                            onPressed: isLoading ? null : loginUser,
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
                        ),
                      ],
                    ),
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
