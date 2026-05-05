import 'dart:io';
import 'package:appfeaturetester/presentation/2_face_verification/controllers/face_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_page.dart';

class FaceVerificationPage extends StatelessWidget {
  FaceVerificationPage({super.key});

  final controller = Get.put(FaceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _imageBox(controller.image1.value),
                    _imageBox(controller.image2.value),
                  ],
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.to(() => CameraPage(
                      onCapture: (file) {
                        controller.setImage1(file);
                      },
                    ));
              },
              child: const Text("Ambil Wajah 1"),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => CameraPage(
                      onCapture: (file) {
                        controller.setImage2(file);
                      },
                    ));
              },
              child: const Text("Ambil Wajah 2"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.compareFaces,
              child: const Text("Compare"),
            ),
            const SizedBox(height: 20),
            Obx(() => Text(
                  controller.result.value,
                  style: const TextStyle(fontSize: 18),
                )),
          ],
        ),
      ),
    );
  }

  Widget _imageBox(File? file) {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child: file == null
          ? const Icon(Icons.person)
          : Image.file(file, fit: BoxFit.cover),
    );
  }
}
