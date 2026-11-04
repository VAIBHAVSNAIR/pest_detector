
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PestDetectorApp());
}

class PestDetectorApp extends StatelessWidget {
  const PestDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Pest Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF238636),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8F5),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? selectedImage;
  bool scanning = false;
  String result = 'No pest scan performed yet';
  String status = 'Waiting for image';
  final ImagePicker picker = ImagePicker();

  Future<void> chooseImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      selectedImage = image;
      result = 'Image selected. Ready to scan.';
      status = 'Ready';
    });
  }

  Future<void> takePhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      selectedImage = image;
      result = 'Photo captured. Ready to scan.';
      status = 'Ready';
    });
  }

  Future<void> scanImage() async {
    if (selectedImage == null) {
      setState(() {
        result = 'Please select an image first.';
        status = 'No image';
      });
      return;
    }

    setState(() {
      scanning = true;
      result = 'Image ready for AI analysis.';
      status = 'Demo mode';
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      scanning = false;
      result =
          'Image selected successfully. Roboflow AI connection is not configured yet.';
      status = 'Awaiting AI connection';
    });
  }

  Widget buildPreview() {
    if (selectedImage == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 65, color: Colors.green),
            SizedBox(height: 12),
            Text(
              'No image selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text('Upload a pest image to begin'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: kIsWeb
            ? Image.network(selectedImage!.path, fit: BoxFit.cover)
            : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget actionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          'AI Pest Detector',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Protect Your Crops',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI-powered pest detection for farmers',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 22),

              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan a Pest',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      buildPreview(),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          actionButton(
                            'Upload Image',
                            Icons.upload_file,
                            chooseImage,
                          ),
                          const SizedBox(width: 10),
                          actionButton(
                            'Camera',
                            Icons.camera_alt,
                            takePhoto,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: scanning ? null : scanImage,
                          icon: const Icon(Icons.search),
                          label: Text(
                            scanning ? 'Scanning...' : 'Scan Image',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detection Result',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 11,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Status: $status'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Card(
                color: Colors.green.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.green,
                        size: 35,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farmer Alerts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              'Pest alerts will be enabled after AI and hardware integration.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'AI-Based Pest Detection & Farmer Alert System',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
