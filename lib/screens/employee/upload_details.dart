import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_application_1/screens/employee/employee_home.dart';

class UploadDetails extends StatefulWidget {
  const UploadDetails({super.key});

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
    "Client & Team Expenses"
  ];

  final List<String> sourceOptions = [
    "Personal Card",
    "Company Card"
  ];

  void _submitData() async {
    var box = Hive.box('userBox');

    var entry = {
      'purpose': _selectedPurpose,
      'source': _selectedSource,
      'date': _dateController.text,
      'invoice': _invoiceController.text,
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'status': 'Pending',
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
              // Purpose dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Purpose of Expense",
                  border: OutlineInputBorder(),
                ),
                value: _selectedPurpose,
                items: purposeOptions.map((purpose) {
                  return DropdownMenuItem(
                    value: purpose,
                    child: Text(purpose),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPurpose = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Source dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Source of Payment",
                  border: OutlineInputBorder(),
                ),
                value: _selectedSource,
                items: sourceOptions.map((source) {
                  return DropdownMenuItem(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSource = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date input
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date",
                  hintText: "Enter date (e.g., 2023-07-01)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice number input
              TextFormField(
                controller: _invoiceController,
                decoration: const InputDecoration(
                  labelText: "Invoice Number",
                  hintText: "Enter invoice number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  hintText: "Enter amount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description input
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

              // Submit button
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
