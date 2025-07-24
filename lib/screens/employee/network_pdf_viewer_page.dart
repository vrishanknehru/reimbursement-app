import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NetworkPdfViewerPage extends StatefulWidget {
  final String pdfUrl; // The network PDF URL to display

  const NetworkPdfViewerPage({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<NetworkPdfViewerPage> createState() => _NetworkPdfViewerPageState();
}

class _NetworkPdfViewerPageState extends State<NetworkPdfViewerPage> {
  String? _localPdfPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      print('DEBUG: Attempting to download PDF for full view from: ${widget.pdfUrl}');
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/full_view_pdf_${DateTime.now().microsecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
        print('DEBUG: PDF downloaded for full view to: $_localPdfPath');
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading PDF for full view: $e');
      setState(() {
        _error = 'Failed to load PDF: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up temporary PDF file if it exists
    if (_localPdfPath != null && File(_localPdfPath!).existsSync()) {
      File(_localPdfPath!).delete().catchError((e) => print('Error deleting temp full-view PDF: $e'));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF View"),
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading PDF..."),
                ],
              )
            : _localPdfPath != null
                ? PDFView(
                    filePath: _localPdfPath!,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: 0,
                    fitEachPage: true,
                    onError: (error) {
                      print('DEBUG: PDFView full screen error: $error');
                      setState(() {
                        _error = 'Error rendering PDF: $error';
                      });
                    },
                    onRender: (_pages) {
                      print('DEBUG: PDF rendered $_pages pages in full screen');
                    },
                  )
                : Text(
                    _error ?? 'Could not load PDF.',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
      ),
    );
  }
}