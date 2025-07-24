import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/local_image_viewer.dart';
import 'package:flutter_application_1/screens/employee/local_pdf_viewer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/employee/employee_home.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; 
import 'package:path_provider/path_provider.dart'; 

class UploadDetails extends StatefulWidget {
  final String? scannedAmount;
  final String? scannedInvoice;
  final String? scannedDate;
  final File? imageFile;
  final String userId;
  final String userEmail;

  const UploadDetails({
    super.key,
    this.scannedAmount,
    this.scannedInvoice,
    this.scannedDate,
    this.imageFile,
    required this.userId,
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
    String? publicUrl;

    try {
      final userId = widget.userId;

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: User ID missing for submission. Please try logging in again.",
              ),
            ),
          );
        }
        print('DEBUG_UPLOAD: Aborting submission because userId is empty.');
        return;
      }

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

      String uploadFileName =
          'bill_${DateTime.now().millisecondsSinceEpoch}.${widget.imageFile!.path.split('.').last.toLowerCase()}';
      String storageFilePath = 'bills/${userId}/$uploadFileName';
      print('DEBUG_UPLOAD: Full storage file path: $storageFilePath');

      try {
        final uploadedFileNameResponse = await supabase.storage
            .from('receipts')
            .upload(storageFilePath, widget.imageFile!);

        print(
          'DEBUG_UPLOAD: Raw response from supabase.storage.upload: $uploadedFileNameResponse',
        );

        if (uploadedFileNameResponse == null ||
            uploadedFileNameResponse.isEmpty) {
          throw Exception(
            'Supabase Storage upload returned empty or null path.',
          );
        }

        publicUrl = supabase.storage
            .from('receipts')
            .getPublicUrl(storageFilePath);
        print('DEBUG_UPLOAD: Public URL generated: $publicUrl');
      } on StorageException catch (se) {
        print(
          'DEBUG_UPLOAD: StorageException caught during upload: ${se.message} (Status: ${se.statusCode})',
        );
        throw Exception('Storage upload error: ${se.message}');
      } catch (e) {
        print('DEBUG_UPLOAD: Unexpected error during file upload: $e');
        throw Exception('File upload failed: ${e.toString()}');
      }

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
            builder: (_) =>
                EmployeeHome(userId: userId, email: widget.userEmail),
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
      print('Upload failed: Unexpected top-level error: $e');
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

              // Image/PDF preview at the bottom of the form, now tappable
              if (widget.imageFile != null)
                GestureDetector(
                  onTap: () {
                    String fileExtension = widget.imageFile!.path
                        .split('.')
                        .last
                        .toLowerCase();
                    if (fileExtension == 'jpg' ||
                        fileExtension == 'jpeg' ||
                        fileExtension == 'png') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocalImageViewerPage(
                            imageFile: widget.imageFile!,
                          ),
                        ),
                      );
                    } else if (fileExtension == 'pdf') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LocalPdfViewerPage(pdfFile: widget.imageFile!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Tap to view not available for this file type.",
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _buildFilePreview(widget.imageFile!),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid,
                    ), // Changed from dashed to solid
                    color: Colors.grey[100],
                  ),
                  child: const Text(
                    'No image selected for preview',
                    style: TextStyle(color: Colors.grey),
                  ),
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

  Widget _buildFilePreview(File file) {
    print('DEBUG: _buildFilePreview called for: ${file.path}');
    if (!file.existsSync()) {
      print(
        'DEBUG: _buildFilePreview: File does NOT exist at path: ${file.path}',
      );
      return const Center(
        child: Text(
          'File not found for preview',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    String fileExtension = file.path.split('.').last.toLowerCase();

    if (fileExtension == 'pdf') {
      return IgnorePointer(
        // Ignore pointer events on PDFView so GestureDetector can catch taps
        ignoring: true,
        child: SizedBox(
          height: 200, // Constrain height
          width: double.infinity,
          child: PDFView(
            filePath: file.path, // Use the local file path directly
            enableSwipe: true,
            swipeHorizontal: false, // Vertical swipe for small preview
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            onError: (error) {
              print('DEBUG: PDFView in preview error: $error');
            },
            onRender: (_pages) {
              print('DEBUG: PDF preview rendered $_pages pages');
            },
          ),
        ),
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
