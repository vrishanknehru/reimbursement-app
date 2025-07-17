// // Relevant imports
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_application_1/screens/employee/employee_home.dart';

// class UploadDetails extends StatefulWidget {
//   final String? scannedAmount;
//   final String? scannedInvoice;
//   final String? scannedDate;
//   final List<File>? imageFiles;

//   const UploadDetails({
//     super.key,
//     this.scannedAmount,
//     this.scannedInvoice,
//     this.scannedDate,
//     this.imageFiles,
//   });

//   @override
//   State<UploadDetails> createState() => _UploadDetailsState();
// }

// class _UploadDetailsState extends State<UploadDetails> {
//   final _dateController = TextEditingController();
//   final _invoiceController = TextEditingController();
//   final _amountController = TextEditingController();
//   final _descriptionController = TextEditingController();

//   String? _selectedPurpose;
//   String? _selectedSource;

//   final List<String> purposeOptions = [
//     "Travel & Logistics",
//     "Work Essentials",
//     "Client & Team Expenses",
//   ];
//   final List<String> sourceOptions = ["Personal Card", "Company Card"];

//   List<File> attachedFiles = [];

//   @override
//   void initState() {
//     super.initState();
//     if (widget.scannedDate != null) {
//       _dateController.text = widget.scannedDate!;
//     }
//     if (widget.scannedInvoice != null) {
//       _invoiceController.text = widget.scannedInvoice!;
//     }
//     if (widget.scannedAmount != null) {
//       _amountController.text = widget.scannedAmount!;
//     }
//     if (widget.imageFiles != null) {
//       attachedFiles = widget.imageFiles!;
//     }
//   }

//   void _submitData() async {
//     if (_selectedPurpose == null ||
//         _selectedSource == null ||
//         _dateController.text.isEmpty ||
//         _invoiceController.text.isEmpty ||
//         _amountController.text.isEmpty ||
//         _descriptionController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all fields")),
//       );
//       return;
//     }

//     var box = Hive.box('userBox');

//     var entry = {
//       'purpose': _selectedPurpose,
//       'source': _selectedSource,
//       'date': _dateController.text,
//       'invoiceNumber': _invoiceController.text,
//       'amount': _amountController.text,
//       'description': _descriptionController.text,
//       'imagePaths': attachedFiles.map((f) => f.path).toList(),
//       'status': 'processing',
//     };

//     List existing = box.get('entries', defaultValue: []);
//     existing.add(entry);
//     await box.put('entries', existing);

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const EmployeeHome()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Upload Details")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: "Purpose of Expense",
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _selectedPurpose,
//                 items: purposeOptions
//                     .map((p) => DropdownMenuItem(value: p, child: Text(p)))
//                     .toList(),
//                 onChanged: (val) => setState(() => _selectedPurpose = val),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: "Source of Payment",
//                   border: OutlineInputBorder(),
//                 ),
//                 value: _selectedSource,
//                 items: sourceOptions
//                     .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                     .toList(),
//                 onChanged: (val) => setState(() => _selectedSource = val),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _dateController,
//                 readOnly: true,
//                 decoration: const InputDecoration(
//                   labelText: "Date",
//                   border: OutlineInputBorder(),
//                   suffixIcon: Icon(Icons.calendar_today),
//                 ),
//                 onTap: () async {
//                   DateTime? picked = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime(2100),
//                   );
//                   if (picked != null) {
//                     _dateController.text =
//                         DateFormat('yyyy-MM-dd').format(picked);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _invoiceController,
//                 decoration: const InputDecoration(
//                   labelText: "Invoice Number",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _amountController,
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 decoration: const InputDecoration(
//                   labelText: "Amount",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _descriptionController,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: "Description",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               if (attachedFiles.isNotEmpty)
//                 SizedBox(
//                   height: 150,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: attachedFiles.length,
//                     itemBuilder: (context, index) {
//                       return GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => Scaffold(
//                                 appBar:
//                                     AppBar(title: const Text("Image Preview")),
//                                 body: Center(
//                                   child: Image.file(attachedFiles[index]),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           margin: const EdgeInsets.only(right: 10),
//                           width: 120,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                           ),
//                           child: Image.file(
//                             attachedFiles[index],
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _submitData,
//                 child: const Text("Submit"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
