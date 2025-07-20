import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🐝 Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('userBox');

  // 🧬 Initialize Supabase
  await Supabase.initialize(
    url: 'https://ahhtejzpkdfkneawvtuy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoaHRlanpwa2Rma25lYXd2dHV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4MTg3NjMsImV4cCI6MjA2ODM5NDc2M30.Nkl1IJMjziOnp6qH0tCO4M4qJ_l08tCgJNwdw4rND_Y',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
