import 'dart:convert';
import 'dart:io';
import 'package:appfeaturetester/core/services/face_recognition_service.dart';
import 'package:appfeaturetester/data/models/face_recognition/employee_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceState {
  idle,
  processing,
  success,
  failed,
  notRegistered,
}

class AttendanceController extends GetxController {
  final faceService = FaceRecognitionService();

  // State
  var state = AttendanceState.idle.obs;
  var statusMessage = ''.obs;
  var detectedEmployee = Rx<Employee?>(null);
  var lastSimilarity = 0.0.obs;
  var isServiceReady = false.obs;

  // Data
  var employees = <Employee>[].obs;
  var attendanceRecords = <AttendanceRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initService();
    loadEmployees();
    loadAttendance();
  }

  Future<void> _initService() async {
    await faceService.init();
    isServiceReady.value = faceService.isInitialized;
  }

  // ─── EMPLOYEE MANAGEMENT ───────────────────────────────────────────────────

  Future<void> registerEmployee({
    required String name,
    required String department,
    required File faceImage,
  }) async {
    state.value = AttendanceState.processing;
    statusMessage.value = 'Memproses wajah...';

    final embedding = await faceService.getEmbedding(faceImage);

    if (embedding == null) {
      state.value = AttendanceState.failed;
      statusMessage.value = 'Gagal membaca wajah. Coba lagi.';
      return;
    }

    final employee = Employee(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      department: department,
      embedding: embedding,
    );

    employees.add(employee);
    await _saveEmployees();

    state.value = AttendanceState.success;
    statusMessage.value = '✅ ${name} berhasil didaftarkan!';
  }

  Future<void> deleteEmployee(String id) async {
    employees.removeWhere((e) => e.id == id);
    await _saveEmployees();
  }

  // ─── ATTENDANCE / ABSEN ────────────────────────────────────────────────────

  Future<void> processAttendance(File faceImage) async {
    if (!isServiceReady.value) {
      statusMessage.value = 'Layanan belum siap, harap tunggu...';
      return;
    }

    if (employees.isEmpty) {
      state.value = AttendanceState.notRegistered;
      statusMessage.value = 'Belum ada karyawan terdaftar!';
      return;
    }

    state.value = AttendanceState.processing;
    statusMessage.value = 'Mengenali wajah...';
    detectedEmployee.value = null;

    final queryEmbedding = await faceService.getEmbedding(faceImage);

    if (queryEmbedding == null) {
      state.value = AttendanceState.failed;
      statusMessage.value =
          '❌ Gagal membaca wajah. Pastikan wajah terlihat jelas.';
      return;
    }

    // Cari karyawan dengan similarity tertinggi
    Employee? bestMatch;
    double bestSimilarity = 0.0;

    for (final emp in employees) {
      final similarity = faceService.compare(queryEmbedding, emp.embedding);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = emp;
      }
    }

    lastSimilarity.value = bestSimilarity;

    if (bestMatch != null && faceService.isMatch(bestSimilarity)) {
      detectedEmployee.value = bestMatch;

      // Tentukan check-in atau check-out
      final type = _determineAttendanceType(bestMatch.id);

      final record = AttendanceRecord(
        employeeId: bestMatch.id,
        employeeName: bestMatch.name,
        timestamp: DateTime.now(),
        type: type,
        similarity: bestSimilarity,
      );

      attendanceRecords.insert(0, record);
      await _saveAttendance();

      state.value = AttendanceState.success;
      statusMessage.value =
          '✅ ${bestMatch.name} — ${type == 'check_in' ? 'Masuk' : 'Keluar'}\n'
          'Akurasi: ${(bestSimilarity * 100).toStringAsFixed(1)}%';
    } else {
      state.value = AttendanceState.failed;
      statusMessage.value = '❌ Wajah tidak dikenali\n'
          'Similarity: ${(bestSimilarity * 100).toStringAsFixed(1)}%';
    }
  }

  String _determineAttendanceType(String employeeId) {
    final today = DateTime.now();
    final todayRecords = attendanceRecords.where((r) {
      return r.employeeId == employeeId &&
          r.timestamp.year == today.year &&
          r.timestamp.month == today.month &&
          r.timestamp.day == today.day;
    }).toList();

    // Kalau belum ada atau terakhir check_out → check_in
    if (todayRecords.isEmpty || todayRecords.first.type == 'check_out') {
      return 'check_in';
    }
    return 'check_out';
  }

  void resetState() {
    state.value = AttendanceState.idle;
    statusMessage.value = '';
    detectedEmployee.value = null;
    lastSimilarity.value = 0.0;
  }

  // ─── PERSISTENCE ───────────────────────────────────────────────────────────

  Future<void> _saveEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final list = employees.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('employees', list);
  }

  Future<void> loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('employees') ?? [];
    employees.value =
        list.map((s) => Employee.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    // Simpan hanya 500 record terakhir
    final limited = attendanceRecords.take(500).toList();
    final list = limited.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('attendance_records', list);
  }

  Future<void> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('attendance_records') ?? [];
    attendanceRecords.value =
        list.map((s) => AttendanceRecord.fromJson(jsonDecode(s))).toList();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  List<AttendanceRecord> getRecordsForToday() {
    final today = DateTime.now();
    return attendanceRecords.where((r) {
      return r.timestamp.year == today.year &&
          r.timestamp.month == today.month &&
          r.timestamp.day == today.day;
    }).toList();
  }

  List<AttendanceRecord> getRecordsForEmployee(String employeeId) {
    return attendanceRecords.where((r) => r.employeeId == employeeId).toList();
  }

  @override
  void onClose() {
    faceService.dispose();
    super.onClose();
  }
}
