// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter_application_1/screens/employee/upload_details.dart';

// class SourcePage extends StatelessWidget {
//   const SourcePage({super.key});

//   void _selectSource(BuildContext context, String source) async {
//     var box = Hive.box('userBox');

//     await box.put('selectedSource', source);

//     print("Source saved: ${box.get('selectedSource')}");

//     await Future.delayed(const Duration(milliseconds: 300));

//     // Navigate to next page
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const UploadDetails()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Source")),
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
//                 onPressed: () => _selectSource(context, "Personal Card"),
//                 child: const Text("Personal Card"),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size.fromHeight(60),
//                 ),
//                 onPressed: () => _selectSource(context, "Company Card"),
//                 child: const Text("Company Card"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
