import 'package:appfeaturetester/data/models/face_recognition/employee_model.dart';
import 'package:appfeaturetester/presentation/2_face_recognition/controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryPage extends StatelessWidget {
  AttendanceHistoryPage({super.key});

  final controller = Get.find<AttendanceController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          // Filter Employee
          Obx(() => PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (id) {},
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'all', child: Text('Semua')),
                  ...controller.employees.map((e) => PopupMenuItem(
                        value: e.id,
                        child: Text(e.name),
                      )),
                ],
              )),
        ],
      ),
      body: Obx(() {
        final records = controller.attendanceRecords;
        if (records.isEmpty) {
          return const Center(child: Text('Belum ada riwayat absensi'));
        }

        // Group by date
        final grouped = <String, List<AttendanceRecord>>{};
        for (final r in records) {
          final key = DateFormat('yyyy-MM-dd').format(r.timestamp);
          grouped.putIfAbsent(key, () => []).add(r);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final date = grouped.keys.elementAt(i);
            final dayRecords = grouped[date]!;
            final parsedDate = DateTime.parse(date);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id').format(parsedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                ...dayRecords.map((r) => _historyTile(r)),
                const Divider(),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _historyTile(AttendanceRecord record) {
    final isIn = record.type == 'check_in';
    return ListTile(
      dense: true,
      leading: Icon(
        isIn ? Icons.login : Icons.logout,
        color: isIn ? Colors.green : Colors.orange,
      ),
      title: Text(record.employeeName),
      subtitle: Text(isIn ? 'Masuk' : 'Keluar'),
      trailing: Text(
        DateFormat('HH:mm').format(record.timestamp),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
