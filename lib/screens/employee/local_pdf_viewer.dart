import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import flutter_pdfview

class LocalPdfViewerPage extends StatelessWidget {
  final File pdfFile; // The local PDF file to display

  const LocalPdfViewerPage({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    if (!pdfFile.existsSync()) {
      return Scaffold(
        appBar: AppBar(title: const Text("PDF View Error")),
        body: const Center(
          child: Text(
            "Error: PDF file not found locally.",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pdfFile.path.split('/').last), // Show filename in app bar
      ),
      body: PDFView(
        filePath: pdfFile.path, // Path to the local PDF file
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitEachPage: true, // Fit each page to the width
        onRender: (pages) {
          print("DEBUG: PDF rendered $pages pages in full view");
        },
        onError: (error) {
          print("DEBUG: PDF full view error: $error");
        },
        onViewCreated: (PDFViewController pdfViewController) {
          print("DEBUG: PDF full view created");
        },
      ),
    );
  }
}
