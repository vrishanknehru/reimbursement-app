import 'package:flutter/material.dart';
import 'employee/employee_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  // assets/clogo.png.png
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Image.asset(
      //     'assets/clogo.png.png',
      //     width: 225,
      //     fit: BoxFit.contain,
      //   ),
      //   centerTitle: true,
      //   backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      //   elevation: 0,
      // ),
      body: Container(
        color: const Color.fromARGB(246, 255, 255, 255),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Your image above email and password
                Image.asset(
                  'assets/clogo.png.png',
                  width: 300, 
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20), // spacing between image and form
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  child: Form(
                    child: Column(
                      children: [
                        TextFormField(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MaterialButton(
                            minWidth: double.infinity,
                            onPressed: () {
                              // Navigate to Employee Home
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeHome(),
                                ),
                              );
                            },
                            color: Colors.black,
                            textColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text('Login'),
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
