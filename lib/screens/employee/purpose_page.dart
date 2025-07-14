// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter_application_1/screens/employee/source_of_payment.dart';

// class PurposePage extends StatelessWidget {
//   const PurposePage({super.key});

//   void _selectPurpose(BuildContext context, String purpose) async {
//     var box = Hive.box('userBox');
//     await box.put('selectedPurpose', purpose);

//     print("Purpose saved: ${box.get('selectedPurpose')}");

//     await Future.delayed(const Duration(milliseconds: 300));

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const SourcePage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Purpose of Expense")),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(60),
//                 ),
//                 onPressed: () => _selectPurpose(context, "Travel & Logistics"),
//                 child: const Text("Travel & Logistics"),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(60),
//                 ),
//                 onPressed: () => _selectPurpose(context, "Work Essentials"),
//                 child: const Text("Work Essentials"),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(60),
//                 ),
//                 onPressed: () =>
//                     _selectPurpose(context, "Client & Team Expenses"),
//                 child: const Text("Client & Team Expenses"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
