import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// REMOVED: pdf_render and path_provider imports
import 'upload_details.dart';

class TakeImagePage extends StatefulWidget {
  final String userEmail;

  const TakeImagePage({super.key, required this.userEmail});

  @override
  State<TakeImagePage> createState() => _TakeImagePageState();
}

class _TakeImagePageState extends State<TakeImagePage> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickAndProcessFile(
    BuildContext context, {
    required bool isPdf,
    ImageSource? imageSource,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    File? selectedFile;
    String? fileExtension;

    try {
      if (isPdf) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
          fileExtension = 'pdf';
          print('DEBUG: PDF picked: ${selectedFile.path}');
        }
      } else {
        if (imageSource == null) {
          throw Exception('ImageSource must be provided for image picking.');
        }
        final XFile? pickedXFile = await _imagePicker.pickImage(
          source: imageSource,
        );
        if (pickedXFile != null) {
          selectedFile = File(pickedXFile.path);
          fileExtension = selectedFile.path.split('.').last.toLowerCase();
          print('DEBUG: Image picked: ${selectedFile.path}');
          print('DEBUG: Image file exists: ${selectedFile.existsSync()}');
        }
      }

      if (selectedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected.')));
        }
        return;
      }

      if (!selectedFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected file does not exist on device.'),
            ),
          );
        }
        return;
      }

      String? scannedAmount;
      String? scannedInvoice;
      String? scannedDate;

      // --- OCR PROCESSING LOGIC ---
      // For images, perform OCR. For PDFs, skip OCR (backend will handle).
      if (fileExtension == 'jpg' ||
          fileExtension == 'jpeg' ||
          fileExtension == 'png') {
        print('DEBUG: Performing OCR on image file: ${selectedFile.path}');
        final inputImage = InputImage.fromFile(selectedFile);
        final textRecognizer = GoogleMlKit.vision.textRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(
          inputImage,
        );
        await textRecognizer.close();

        String rawText = recognizedText.text;
        print("DEBUG: Extracted Text from OCR:\n$rawText");

        // Refined OCR parsing logic
        RegExp totalKeywords = RegExp(
          r'\b(total|amount|sum|grand total|balance due)\b',
          caseSensitive: false,
        );
        RegExp amountPattern = RegExp(
          r'\b(?:[\$€£¥]\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\b',
          caseSensitive: false,
        );

        String lowerRawText = rawText.toLowerCase();
        List<String> lines = rawText.split('\n');

        for (int i = 0; i < lines.length; i++) {
          if (totalKeywords.hasMatch(lines[i].toLowerCase())) {
            for (int j = i; j < i + 3 && j < lines.length; j++) {
              Iterable<Match> matches = amountPattern.allMatches(lines[j]);
              if (matches.isNotEmpty) {
                String potentialAmount = matches.last.group(1)!;
                potentialAmount = potentialAmount.replaceAll(',', '.');
                if (double.tryParse(potentialAmount) != null) {
                  scannedAmount = potentialAmount;
                  break;
                }
              }
            }
            if (scannedAmount != null) break;
          }
        }
        if (scannedAmount == null) {
          Iterable<Match> allAmountMatches = amountPattern.allMatches(rawText);
          if (allAmountMatches.isNotEmpty) {
            List<double> possibleAmounts = [];
            for (var match in allAmountMatches) {
              String val = match.group(1)!.replaceAll(',', '.');
              if (double.tryParse(val) != null) {
                possibleAmounts.add(double.parse(val));
              }
            }
            if (possibleAmounts.isNotEmpty) {
              scannedAmount = possibleAmounts
                  .reduce((a, b) => a > b ? a : b)
                  .toString();
            }
          }
        }

        RegExp invoicePattern = RegExp(
          r'\b(?:invoice|inv|bill|#|no\.?|ref\.?)\s*[:#]?\s*([a-zA-Z0-9-]{3,})\b',
          caseSensitive: false,
          multiLine: true,
        );
        Match? invoiceMatch = invoicePattern.firstMatch(rawText);
        if (invoiceMatch != null) {
          scannedInvoice = invoiceMatch.group(1);
        } else {
          RegExp fallbackNumberPattern = RegExp(r'\b\d{6,}\b');
          Match? fallbackMatch = fallbackNumberPattern.firstMatch(rawText);
          if (fallbackMatch != null) {
            scannedInvoice = fallbackMatch.group(0);
          }
        }

        RegExp datePattern = RegExp(
          r'\b(\d{4}[/-]\d{1,2}[/-]\d{1,2})|' +
              r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|' +
              r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},\s+\d{4}\b',
          caseSensitive: false,
        );
        Match? dateMatch = datePattern.firstMatch(rawText);
        if (dateMatch != null) {
          String? extractedDate = dateMatch.group(0);
          if (extractedDate != null) {
            try {
              DateTime parsedDate;
              if (extractedDate.contains('-') &&
                  extractedDate.split('-')[0].length == 4) {
                parsedDate = DateFormat('yyyy-MM-dd').parse(extractedDate);
              } else if (extractedDate.contains('-')) {
                parsedDate = DateFormat('dd-MM-yyyy').parse(extractedDate);
              } else if (extractedDate.contains('/') &&
                  extractedDate.split('/')[0].length <= 2 &&
                  extractedDate.split('/')[2].length == 4) {
                parsedDate = DateFormat('MM/dd/yyyy').parse(extractedDate);
              } else if (extractedDate.contains('/')) {
                parsedDate = DateFormat('dd/MM/yyyy').parse(extractedDate);
              } else {
                parsedDate = DateFormat('MMM d, yyyy').parse(extractedDate);
              }
              scannedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
            } catch (e) {
              print("DEBUG: Failed to parse date: $e - raw: $extractedDate");
              scannedDate = extractedDate;
            }
          }
        }
      } else if (fileExtension == 'pdf') {
        print(
          'DEBUG: PDF selected. Client-side OCR will be skipped. User will fill details manually.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF selected. Please fill details manually.'),
            ),
          );
        }
        // scannedAmount, scannedInvoice, scannedDate remain null for PDFs
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unsupported file type. Please select an image (jpg/png) or PDF.',
              ),
            ),
          );
        }
        return;
      }

      // Navigate to UploadDetails, always passing the ORIGINAL selectedFile
      _navigateToUploadDetails(
        scannedAmount: scannedAmount,
        scannedInvoice: scannedInvoice,
        scannedDate: scannedDate,
        imageFile: selectedFile,
        userEmail: widget.userEmail,
      );
    } catch (e) {
      print("DEBUG: Error during file picking or processing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process file: ${e.toString()}")),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _navigateToUploadDetails({
    String? scannedAmount,
    String? scannedInvoice,
    String? scannedDate,
    required File imageFile,
    required String userEmail,
  }) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadDetails(
            scannedAmount: scannedAmount,
            scannedInvoice: scannedInvoice,
            scannedDate: scannedDate,
            imageFile: imageFile,
            userEmail: userEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Bill")),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Processing bill..."),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndProcessFile(
                      context,
                      isPdf: false,
                      imageSource: ImageSource.camera,
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Image (Camera)"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndProcessFile(
                      context,
                      isPdf: false,
                      imageSource: ImageSource.gallery,
                    ),
                    icon: const Icon(Icons.image),
                    label: const Text("Select Image (Gallery)"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndProcessFile(context, isPdf: true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Select PDF"),
                  ),
                ],
              ),
      ),
    );
  }
}
