import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BillViewerPage extends StatefulWidget {
  final Map<String, dynamic> billData;

  const BillViewerPage({super.key, required this.billData});

  @override
  State<BillViewerPage> createState() => _BillViewerPageState();
}

class _BillViewerPageState extends State<BillViewerPage> {
  String? _localPdfPath;
  bool _isLoadingPdf = true;
  String? _pdfError;

  late String _billUrl;
  late String _appBarTitle;
  late String _purpose;
  late String _source;
  late String _amount;
  late String _billDate;
  late String _invoiceNo;
  late String _description;
  late String _status;
  late String _claimedAtDateOnly;

  @override
  void initState() {
    super.initState();

    _purpose = widget.billData['purpose'] ?? 'N/A';
    _source = widget.billData['source'] ?? 'N/A';
    _amount = (widget.billData['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A';
    _billDate = widget.billData['date'] ?? 'N/A';
    _invoiceNo = widget.billData['invoice_no'] ?? 'N/A';
    _description = widget.billData['description'] ?? 'N/A';
    _status = widget.billData['status']?.toString().toUpperCase() ?? 'UNKNOWN';
    _billUrl = widget.billData['image_url'] ?? '';

    if (widget.billData['created_at'] != null) {
      try {
        final DateTime parsedCreatedAt = DateTime.parse(
          widget.billData['created_at'],
        );
        _claimedAtDateOnly = DateFormat('MMM dd, yyyy').format(parsedCreatedAt);
      } catch (e) {
        print("DEBUG: Error parsing created_at: $e");
        _claimedAtDateOnly = widget.billData['created_at'].toString().split(
          'T',
        )[0];
      }
    } else {
      _claimedAtDateOnly = 'N/A';
    }

    _appBarTitle = _claimedAtDateOnly;

    print('DEBUG BILLVIEWER: Page loaded. Bill URL: $_billUrl');
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (_billUrl.isEmpty || !_billUrl.toLowerCase().endsWith('.pdf')) {
      print('DEBUG: Not a PDF or URL is empty. Skipping PDF load.');
      setState(() {
        _isLoadingPdf = false;
      });
      return;
    }

    try {
      print('DEBUG: Attempting to download PDF from: $_billUrl');
      final response = await http.get(Uri.parse(_billUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/temp_bill_${DateTime.now().microsecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPdfPath = file.path;
          _isLoadingPdf = false;
        });
        print('DEBUG: PDF downloaded to: $_localPdfPath');
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading PDF: $e');
      setState(() {
        _pdfError = 'Failed to load PDF: ${e.toString()}';
        _isLoadingPdf = false;
      });
    }
  }

  @override
  void dispose() {
    if (_localPdfPath != null && File(_localPdfPath!).existsSync()) {
      File(
        _localPdfPath!,
      ).delete().catchError((e) => print('Error deleting temp PDF: $e'));
    }
    super.dispose();
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green, size: 36);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red, size: 36);
      default:
        return const Icon(Icons.hourglass_top, color: Colors.orange, size: 36);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPdf = _billUrl.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expense Details',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusIcon(_status),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Claim Sent At', _claimedAtDateOnly),
                    _buildDetailRow('Purpose', _purpose),
                    _buildDetailRow('Source', _source),
                    _buildDetailRow('Amount', '\$$_amount'),
                    _buildDetailRow('Bill Date', _billDate),
                    _buildDetailRow('Invoice No.', _invoiceNo),
                    _buildDetailRow('Description', _description),
                    _buildDetailRow('Status', _status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Attached Bill',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Center(
              child: _billUrl.isEmpty
                  ? const Text(
                      "No attached bill found.",
                      style: TextStyle(color: Colors.grey),
                    )
                  : isPdf
                  ? _isLoadingPdf
                        ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Loading PDF..."),
                            ],
                          )
                        : _localPdfPath != null
                        ? SizedBox(
                            height: 400,
                            child: PDFView(
                              filePath: _localPdfPath!,
                              enableSwipe: true,
                              swipeHorizontal: true,
                              autoSpacing: false,
                              pageFling: false,
                              pageSnap: false,
                              onError: (error) {
                                print('DEBUG: PDFView error: $error');
                                setState(() {
                                  _pdfError = 'Error rendering PDF: $error';
                                });
                              },
                              onRender: (pages) {
                                print('DEBUG: PDF rendered $pages pages');
                              },
                              onViewCreated: (PDFViewController vc) {
                                print('DEBUG: PDFView created');
                              },
                            ),
                          )
                        : Text(
                            _pdfError ?? 'Could not load PDF.',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          )
                  : CachedNetworkImage(
                      imageUrl: _billUrl,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) {
                        print(
                          'DEBUG: CachedNetworkImage error: $error (URL: $url)',
                        );
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 50),
                            SizedBox(height: 8),
                            Text("Failed to load image"),
                          ],
                        );
                      },
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
