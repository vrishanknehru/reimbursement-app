import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/upload_details.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class TakeImagePage extends StatefulWidget {
  final String userId; // Passed from EmployeeHome
  final String userEmail; // Passed from EmployeeHome

  const TakeImagePage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<TakeImagePage> createState() => _TakeImagePageState();
}

class _TakeImagePageState extends State<TakeImagePage> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

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
      String? scannedInvoice; // This will always be null
      String? scannedDate;

      // --- OCR PROCESSING LOGIC ---
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

        // Date: Robust parsing for MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD
        RegExp datePattern = RegExp(
          r'\b(\d{4}[/-]\d{1,2}[/-]\d{1,2})|'
          r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|'
          r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},\s+\d{4}\b', // Month DD, YYYY
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

        // Amount: Refined to find the largest amount, now explicitly excluding phone numbers.
        RegExp amountPattern = RegExp(
          r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)', // Matches numbers with optional thousands separators and decimals
          caseSensitive: false,
        );
        // Pattern to identify sequences that look like phone numbers within the text
        RegExp phoneLikePattern = RegExp(
          r'\b(?:\+\d{1,3}[\s-]*)?(?:\d{2,4}[-\s]?){2,}\d{2,4}\b', // e.g., +1 234-567-8900, 215 658 98 75
          caseSensitive: false,
        );

        List<double> foundAmounts = [];
        Iterable<Match> allAmountMatches = amountPattern.allMatches(rawText);
        for (var match in allAmountMatches) {
          String? value = match.group(1);
          if (value != null) {
            String contextAroundMatch = rawText.substring(
              (match.start - 15).clamp(0, rawText.length),
              (match.end + 15).clamp(0, rawText.length),
            );

            if (!phoneLikePattern.hasMatch(contextAroundMatch)) {
              value = value.replaceAll(',', '.').trim();
              double? parsedValue = double.tryParse(value);
              if (parsedValue != null) {
                foundAmounts.add(parsedValue);
              }
            } else {
              print(
                'DEBUG: Excluded potential phone number component from amount: ${match.group(0)} (Context: "$contextAroundMatch")',
              );
            }
          }
        }

        if (foundAmounts.isNotEmpty) {
          foundAmounts.sort((a, b) => b.compareTo(a));
          scannedAmount = foundAmounts.first.toString();
          print('DEBUG: Found amounts (filtered): $foundAmounts');
          print('DEBUG: Selected largest amount: $scannedAmount');
        } else {
          scannedAmount = null;
          print('DEBUG: No valid amounts found by OCR.');
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

      _navigateToUploadDetails(
        scannedAmount: scannedAmount,
        scannedInvoice: scannedInvoice, // This is explicitly null
        scannedDate: scannedDate,
        imageFile: selectedFile,
        userId: widget.userId,
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
    required String userId,
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
            userId: userId,
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
