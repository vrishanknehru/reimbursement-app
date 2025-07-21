import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/employee/employee_home.dart';

class UploadDetails extends StatefulWidget {
  final String? scannedAmount;
  final String? scannedInvoice;
  final String? scannedDate;
  final File? imageFile;
  final String userEmail;

  const UploadDetails({
    super.key,
    this.scannedAmount,
    this.scannedInvoice,
    this.scannedDate,
    this.imageFile,
    required this.userEmail,
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
  bool _isSubmitting = false;

  final List<String> purposeOptions = [
    "Travel & Logistics",
    "Work Essentials",
    "Client & Team Expenses",
  ];

  final List<String> sourceOptions = ["Personal Card", "Company Card"];

  @override
  void initState() {
    super.initState();

    if (widget.scannedDate != null) _dateController.text = widget.scannedDate!;
    if (widget.scannedInvoice != null) {
      _invoiceController.text = widget.scannedInvoice!;
    }
    if (widget.scannedAmount != null) {
      final cleanAmount = widget.scannedAmount!.replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      _amountController.text = cleanAmount;
    }
  }

  Future<void> _submitData() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final supabase = Supabase.instance.client;
    String? userId;
    String? publicUrl;

    try {
      final userResponse = await supabase
          .from('users')
          .select('id')
          .eq('email', widget.userEmail)
          .maybeSingle();

      if (userResponse == null || userResponse['id'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User ID not found for this email. Cannot submit."),
            ),
          );
        }
        return;
      }
      userId = userResponse['id'] as String;

      if (_selectedPurpose == null ||
          _selectedSource == null ||
          _dateController.text.isEmpty ||
          _invoiceController.text.isEmpty ||
          _amountController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          widget.imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please fill all fields and attach an image."),
            ),
          );
        }
        return;
      }

      double? amount;
      try {
        amount = double.parse(_amountController.text);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid amount.")),
          );
        }
        return;
      }

      final uploadedFileName = await supabase.storage
          .from('receipts')
          .upload(
            'bills/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            widget.imageFile!,
          );

      publicUrl = supabase.storage
          .from('receipts')
          .getPublicUrl(
            'bills/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      final dbResponse = await supabase.from('bills').insert({
        'user_id': userId,
        'purpose': _selectedPurpose,
        'source': _selectedSource,
        'date': _dateController.text,
        'invoice_no': _invoiceController.text,
        'amount': amount,
        'description': _descriptionController.text,
        'image_url': publicUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bill submitted successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHome(email: widget.userEmail),
          ),
        );
      }
    } on PostgrestException catch (e) {
      print('Upload failed: PostgrestException during DB insert: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Database error: ${e.message}")));
      }
    } catch (e) {
      print('Upload failed: Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${e.toString()}")),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
                  labelText: "Date (YYYY-MM-DD)",
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
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

              // Image preview at the bottom of the form
              if (widget.imageFile != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _buildFilePreview(
                    widget.imageFile!,
                  ), // This helper handles basic image/PDF
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitData,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build file preview (handles basic image/PDF icon)
  Widget _buildFilePreview(File file) {
    String fileExtension = file.path.split('.').last.toLowerCase();

    if (fileExtension == 'pdf') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(
            '${file.path.split('/').last}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const Text(
            '(PDF Preview Not Available)', // Will show this for PDFs
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    } else if (fileExtension == 'jpg' ||
        fileExtension == 'jpeg' ||
        fileExtension == 'png') {
      return Image.file(file, fit: BoxFit.contain);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            '${file.path.split('/').last}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const Text(
            '(Unsupported File Type)',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      );
    }
  }
}
