import 'dart:io'; // ✅ Added for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart'; // ✅ Added for OCR
import 'upload_details.dart';

class TakeImagePage extends StatefulWidget {
  const TakeImagePage({super.key});

  @override
  State<TakeImagePage> createState() => _TakeImagePageState();
}

class _TakeImagePageState extends State<TakeImagePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // ✅ OCR logic
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    String rawText = recognizedText.text;

    // ✅ Simple parsing logic (basic)
    String? amount;
    String? invoice;
    String? date;

    // Regex for amount
    RegExp amountRegex = RegExp(r'(\d+[.,]?\d*)');
    if (rawText.contains("Total")) {
      int index = rawText.indexOf("Total");
      String sub = rawText.substring(index);
      Match? m = amountRegex.firstMatch(sub);
      if (m != null) {
        amount = m.group(0);
      }
    }

    // Regex for invoice number (example)
    RegExp invoiceRegex = RegExp(r'Invoice\s*No\.?\s*\d+', caseSensitive: false);
    Match? invMatch = invoiceRegex.firstMatch(rawText);
    if (invMatch != null) {
      invoice = invMatch.group(0)?.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // Regex for date (yyyy-mm-dd or similar)
    RegExp dateRegex = RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}');
    Match? dateMatch = dateRegex.firstMatch(rawText);
    if (dateMatch != null) {
      date = dateMatch.group(0);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadDetails(
            scannedAmount: amount,
            scannedInvoice: invoice,
            scannedDate: date,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Take Image")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("Take Image"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("Image from Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}
