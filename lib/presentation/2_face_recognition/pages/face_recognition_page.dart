import 'dart:io';
import 'package:appfeaturetester/data/models/face_recognition/employee_model.dart';
import 'package:appfeaturetester/presentation/2_face_recognition/controllers/attendance_controller.dart';
import 'package:appfeaturetester/presentation/2_face_recognition/pages/attendance_history_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'camera_page.dart';
import 'register_face_page.dart';

class FaceRecognitionPage extends StatelessWidget {
  FaceRecognitionPage({super.key});

  final controller = Get.put(AttendanceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Wajah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => Get.to(() => AttendanceHistoryPage()),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Daftar Karyawan',
            onPressed: () => Get.to(() => const RegisterFacePage()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildScanButton(context),
            const SizedBox(height: 24),
            _buildTodayAttendance(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Obx(() {
      final state = controller.state.value;
      final employee = controller.detectedEmployee.value;

      Color cardColor;
      IconData icon;

      switch (state) {
        case AttendanceState.success:
          cardColor = Colors.green;
          icon = Icons.check_circle;
          break;
        case AttendanceState.failed:
          cardColor = Colors.red;
          icon = Icons.cancel;
          break;
        case AttendanceState.processing:
          cardColor = Colors.blue;
          icon = Icons.face;
          break;
        case AttendanceState.notRegistered:
          cardColor = Colors.orange;
          icon = Icons.warning;
          break;
        default:
          cardColor = Colors.grey;
          icon = Icons.fingerprint;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            if (state == AttendanceState.processing)
              const CircularProgressIndicator(color: Colors.white)
            else
              Icon(icon, size: 56, color: Colors.white),
            const SizedBox(height: 12),
            if (employee != null) ...[
              Text(
                employee.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                employee.department,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              controller.statusMessage.value.isEmpty
                  ? 'Tap tombol untuk melakukan absen'
                  : controller.statusMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildScanButton(BuildContext context) {
    return Obx(() {
      final isProcessing = controller.state.value == AttendanceState.processing;

      return Column(
        children: [
          GestureDetector(
            onTap: isProcessing
                ? null
                : () async {
                    controller.resetState();
                    File? capturedFile;

                    await Get.to(() => CameraPage(
                          title: 'Scan Wajah untuk Absen',
                          onCapture: (file) {
                            capturedFile = file;
                          },
                        ));

                    if (capturedFile != null) {
                      await controller.processAttendance(capturedFile!);
                    }
                  },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProcessing ? Colors.grey : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face_retouching_natural,
                            color: Colors.white, size: 52),
                        SizedBox(height: 6),
                        Text('ABSEN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
                '${controller.employees.length} karyawan terdaftar',
                style: const TextStyle(color: Colors.grey),
              )),
        ],
      );
    });
  }

  Widget _buildTodayAttendance() {
    return Obx(() {
      final todayRecords = controller.getRecordsForToday();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Absensi Hari Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada absensi hari ini',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...todayRecords.map((r) => _attendanceCard(r)),
        ],
      );
    });
  }

  Widget _attendanceCard(AttendanceRecord record) {
    final isIn = record.type == 'check_in';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIn ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            isIn ? Icons.login : Icons.logout,
            color: isIn ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(record.employeeName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${isIn ? 'Masuk' : 'Keluar'} • ${DateFormat('HH:mm').format(record.timestamp)}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${(record.similarity * 100).toStringAsFixed(0)}%',
            style:
                TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
