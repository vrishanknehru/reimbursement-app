import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/employee/employee_home.dart';

class UploadDetails extends StatefulWidget {
  final String? scannedAmount;
  final String? scannedInvoice;
  final String? scannedDate;
  final File? imageFile;

  const UploadDetails({
    super.key,
    this.scannedAmount,
    this.scannedInvoice,
    this.scannedDate,
    this.imageFile,
  });

  @override
  State<UploadDetails> createState() => _UploadDetailsState();
}

class _UploadDetailsState extends State<UploadDetails> {
  final _dateController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedPurpose;
  String? _selectedSource;

  final List<String> purposeOptions = [
    "Travel & Logistics",
    "Work Essentials",
    "Client & Team Expenses",
  ];

  final List<String> sourceOptions = ["Personal Card", "Company Card"];

  @override
  void initState() {
    super.initState();

    if (widget.scannedDate != null) {
      _dateController.text = widget.scannedDate!;
    }
    if (widget.scannedInvoice != null) {
      _invoiceController.text = widget.scannedInvoice!;
    }
    if (widget.scannedAmount != null) {
      _amountController.text = widget.scannedAmount!;
    }
  }

  void _submitData() async {
    if (_selectedPurpose == null ||
        _selectedSource == null ||
        _dateController.text.isEmpty ||
        _invoiceController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    var box = Hive.box('userBox');

    var entry = {
      'purpose': _selectedPurpose,
      'source': _selectedSource,
      'date': _dateController.text,
      'invoiceNumber': _invoiceController.text,
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'status': 'processing',
      'imagePath': widget.imageFile?.path,
    };

    List existing = box.get('entries', defaultValue: []);
    existing.add(entry);
    await box.put('entries', existing);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeHome()),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _invoiceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Purpose of Expense",
                  border: OutlineInputBorder(),
                ),
                value: _selectedPurpose,
                items: purposeOptions.map((purpose) {
                  return DropdownMenuItem(value: purpose, child: Text(purpose));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPurpose = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Source of Payment",
                  border: OutlineInputBorder(),
                ),
                value: _selectedSource,
                items: sourceOptions.map((source) {
                  return DropdownMenuItem(value: source, child: Text(source));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date",
                  hintText: "Select date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    String formattedDate = DateFormat(
                      'yyyy-MM-dd',
                    ).format(pickedDate);
                    setState(() {
                      _dateController.text = formattedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _invoiceController,
                decoration: const InputDecoration(
                  labelText: "Invoice Number",
                  hintText: "Enter invoice number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Amount",
                  hintText: "Enter amount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Enter description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // display image preview if imageFile is not null
              if (widget.imageFile != null)
                GestureDetector(
                  onTap: () {
                    // Show full screen image
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text("Image Preview")),
                          body: Center(child: Image.file(widget.imageFile!)),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.file(widget.imageFile!, fit: BoxFit.cover),
                  ),
                ),

              ElevatedButton(
                onPressed: _submitData,
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
