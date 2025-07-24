import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NetworkImageViewerPage extends StatelessWidget {
  final String imageUrl; // The network image URL to display

  const NetworkImageViewerPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image View"),
        backgroundColor: Colors.black, // Dark background for image view
      ),
      backgroundColor: Colors.black, // Dark background for image view
      body: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) =>
              const CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              SizedBox(height: 8),
              Text(
                "Failed to load image",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          fit: BoxFit.contain, // Fit image within screen bounds
        ),
      ),
    );
  }
}
