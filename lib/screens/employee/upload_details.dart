import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'employee_home.dart';

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
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please log in first")));
        Navigator.pop(context);
      });
    }

    if (widget.scannedDate != null) _dateController.text = widget.scannedDate!;
    if (widget.scannedInvoice != null)
      _invoiceController.text = widget.scannedInvoice!;
    if (widget.scannedAmount != null)
      _amountController.text = widget.scannedAmount!;
  }

  Future<void> _submitData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (_selectedPurpose == null ||
        _selectedSource == null ||
        _dateController.text.isEmpty ||
        _invoiceController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        widget.imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      final fileName = 'bill_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'bills/$fileName';

      await supabase.storage
          .from('bills')
          .upload(storagePath, widget.imageFile!);

      final publicUrl = supabase.storage
          .from('bills')
          .getPublicUrl(storagePath);

      await supabase.from('bills').insert({
        'user_id': user.id,
        'purpose': _selectedPurpose,
        'source': _selectedSource,
        'date': _dateController.text,
        'invoice': _invoiceController.text,
        'amount': _amountController.text,
        'description': _descriptionController.text,
        'image_url': publicUrl,
        'status': 'processing',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bill submitted successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeHome()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
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
                onChanged: (value) => setState(() => _selectedPurpose = value),
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
                onChanged: (value) => setState(() => _selectedSource = value),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _dateController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _invoiceController,
                decoration: const InputDecoration(
                  labelText: "Invoice Number",
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              if (widget.imageFile != null)
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.file(widget.imageFile!, fit: BoxFit.cover),
                ),

              const SizedBox(height: 20),
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
