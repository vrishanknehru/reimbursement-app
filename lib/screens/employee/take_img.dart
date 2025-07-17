import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'upload_details.dart';

class TakeImagePage extends StatefulWidget {
  const TakeImagePage({super.key});

  @override
  State<TakeImagePage> createState() => _TakeImagePageState();
}

class _TakeImagePageState extends State<TakeImagePage> {
  final ImagePicker _picker = ImagePicker();

  // Reusable function to handle both camera and gallery input
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // Run OCR
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();

    String rawText = recognizedText.text;
    print("Extracted Text:\n$rawText");

    // Extract values
    String? amount;
    String? invoice;
    String? date;

    // Amount
    RegExp amountRegex = RegExp(r'\$([0-9]+[.,]?[0-9]*)');
    Iterable<Match> allAmountMatches = amountRegex.allMatches(rawText);
    if (allAmountMatches.isNotEmpty) {
      amount = allAmountMatches.last.group(1);
    }

    // Invoice
    List<String> lines = rawText.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains("invoice")) {
        RegExp numberRegex = RegExp(r'\d{3,}');
        Match? match = numberRegex.firstMatch(lines[i]);
        if (match != null) {
          invoice = match.group(0);
          break;
        } else if (i + 1 < lines.length) {
          Match? nextMatch = numberRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            invoice = nextMatch.group(0);
            break;
          }
        }
      }
    }

    // Date
    RegExp dateRegex = RegExp(r'\d{2}\s*/\s*\d{2}\s*/\s*\d{4}');
    Match? dateMatch = dateRegex.firstMatch(rawText);
    if (dateMatch != null) {
      date = dateMatch.group(0)?.replaceAll(RegExp(r'\s'), '');
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadDetails(
            scannedAmount: amount,
            scannedInvoice: invoice,
            scannedDate: date,
            imageFile: imageFile,
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
