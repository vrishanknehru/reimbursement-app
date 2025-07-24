import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/screens/employee/bill_viewer_page.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final String userId;
  final String email;

  const HistoryPage({super.key, required this.userId, required this.email});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allUserBills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllBills();
  }

  Future<void> _fetchAllBills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userId;

      final billsResponse = await supabase
          .from('bills')
          .select(
            'purpose, source, amount, date, invoice_no, description, status, created_at, image_url, admin_notes',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _allUserBills = List<Map<String, dynamic>>.from(billsResponse);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching all bills for history: $e");
      setState(() {
        _errorMessage = "Failed to load history: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'pending':
        return const Icon(Icons.hourglass_top, color: Colors.orange);
      case 'processing':
        return const Icon(Icons.hourglass_empty, color: Colors.blueGrey);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bill History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          : _allUserBills.isEmpty
          ? const Center(
              child: Text("No entries yet", style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: _allUserBills.length,
              itemBuilder: (context, index) {
                final entry = _allUserBills[index];

                String formattedDate = 'N/A';
                if (entry['created_at'] != null) {
                  try {
                    final DateTime parsedCreatedAt = DateTime.parse(
                      entry['created_at'],
                    );
                    formattedDate = DateFormat(
                      'MMM dd, yyyy',
                    ).format(parsedCreatedAt);
                  } catch (e) {
                    print("Error parsing created_at for display: $e");
                    formattedDate = entry['created_at'].toString().split(
                      'T',
                    )[0];
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    dense: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          entry['description'] ?? 'No Description',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${entry['purpose'] ?? 'N/A Purpose'} | ${entry['source'] ?? 'N/A Source'}",
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          "Amount: ₹${(entry['amount'] as num?)?.toStringAsFixed(2) ?? 'N/A'} | Invoice: ${entry['invoice_no'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: _buildStatusIcon(
                      entry['status']?.toString() ?? 'processing',
                    ),
                    onTap: () {
                      final billUrl = entry['image_url'];
                      if (billUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillViewerPage(
                              billData: entry,
                              isAdmin:
                                  false, // Pass isAdmin false for employee view
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "No bill image/PDF found for this entry.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
