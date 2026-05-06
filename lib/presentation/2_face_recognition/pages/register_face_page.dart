import 'dart:io';
import 'package:appfeaturetester/presentation/2_face_recognition/controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'camera_page.dart';

class RegisterFacePage extends StatefulWidget {
  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> {
  final controller = Get.find<AttendanceController>();
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  File? _capturedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    await Get.to(() => CameraPage(
          title: 'Foto Wajah Karyawan',
          onCapture: (file) {
            setState(() => _capturedImage = file);
          },
        ));
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final dept = _deptController.text.trim();

    if (name.isEmpty || dept.isEmpty) {
      Get.snackbar('Error', 'Nama dan departemen wajib diisi',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (_capturedImage == null) {
      Get.snackbar('Error', 'Foto wajah belum diambil',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    await controller.registerEmployee(
      name: name,
      department: dept,
      faceImage: _capturedImage!,
    );

    setState(() => _isLoading = false);

    if (controller.state.value == AttendanceState.success) {
      Get.back();
      Get.snackbar('Berhasil', controller.statusMessage.value,
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Gagal', controller.statusMessage.value,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Karyawan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Face preview
            Center(
              child: GestureDetector(
                onTap: _openCamera,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _capturedImage != null
                      ? Image.file(_capturedImage!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.blue),
                            SizedBox(height: 8),
                            Text('Ambil Foto',
                                style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deptController,
              decoration: const InputDecoration(
                labelText: 'Departemen',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Daftarkan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
