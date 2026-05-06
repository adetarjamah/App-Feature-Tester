import 'dart:convert';

class Employee {
  final String id;
  final String name;
  final String department;
  final List<double> embedding;

  Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.embedding,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'embedding': embedding,
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'],
        name: json['name'],
        department: json['department'],
        embedding: List<double>.from(json['embedding']),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Employee.fromJsonString(String jsonString) =>
      Employee.fromJson(jsonDecode(jsonString));
}

class AttendanceRecord {
  final String employeeId;
  final String employeeName;
  final DateTime timestamp;
  final String type; // 'check_in' | 'check_out'
  final double similarity;

  AttendanceRecord({
    required this.employeeId,
    required this.employeeName,
    required this.timestamp,
    required this.type,
    required this.similarity,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'similarity': similarity,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        employeeId: json['employeeId'],
        employeeName: json['employeeName'],
        timestamp: DateTime.parse(json['timestamp']),
        type: json['type'],
        similarity: json['similarity'],
      );
}
