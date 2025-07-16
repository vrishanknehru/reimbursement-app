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
  // selecting image
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // processing text from the image
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();

    String rawText = recognizedText.text;
    print(rawText);

    // initializing variables
    String? amount;
    String? invoice;
    String? date;

    //amt

    RegExp amountRegex = RegExp(r'\$([0-9]+[.,]?[0-9]*)');
    Iterable<Match> allAmountMatches = amountRegex.allMatches(rawText);

    if (allAmountMatches.isNotEmpty) {
      Match lastAmountMatch = allAmountMatches.last;
      amount = lastAmountMatch.group(1);
    }
    List<String> lines = rawText.split('\n');

    //invoice

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.toLowerCase().contains("invoice")) {
        RegExp numberRegex = RegExp(r'\d{3,}');
        Match? match = numberRegex.firstMatch(line);
        if (match != null) {
          invoice = match.group(0);
          break;
        } else if (i + 1 < lines.length) {
          String nextLine = lines[i + 1];
          Match? nextMatch = numberRegex.firstMatch(nextLine);
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
