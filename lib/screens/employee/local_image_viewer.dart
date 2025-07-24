import 'dart:io';
import 'package:flutter/material.dart';

class LocalImageViewerPage extends StatelessWidget {
  final File imageFile; // The local image file to display

  const LocalImageViewerPage({
    super.key,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Preview"),
      ),
      body: Center(
        child: Image.file(
          imageFile, // Display the local image file
          fit: BoxFit.contain, // Contain the image within the screen
        ),
      ),
    );
  }
}