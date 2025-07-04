import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/employee/employee_home.dart';
// import 'employee/employee_home.dart';

class UploadDetails extends StatelessWidget {
  const UploadDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Date input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Date",
                  hintText: "Enter date (e.g., 2023-07-01)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice number input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Invoice Number",
                  hintText: "Enter invoice number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  hintText: "Enter amount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Enter description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Image/status placeholder
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(child: Text("Image / Status Placeholder")),
              ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmployeeHome()),
                  );
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
