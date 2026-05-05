import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  final Function(File) onCapture;

  const CameraPage({super.key, required this.onCapture});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      debugPrint("No camera available");
      return;
    }

    // 🔥 cari kamera depan, kalau ga ada fallback ke belakang
    final selectedCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(selectedCamera, ResolutionPreset.medium);

    await controller!.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller == null) {
      return const Scaffold(
        body: Center(child: Text("Kamera tidak tersedia")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ambil Foto")),
      body: Column(
        children: [
          Expanded(child: CameraPreview(controller!)),
          ElevatedButton(
            onPressed: () async {
              final file = await controller!.takePicture();
              widget.onCapture(File(file.path));
              Navigator.pop(context);
            },
            child: const Text("Capture"),
          ),
        ],
      ),
    );
  }
}
