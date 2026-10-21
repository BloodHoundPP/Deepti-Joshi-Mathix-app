class AttendanceRecordModel {
  final String id;
  final String batchId;
  final DateTime attendanceDate;
  final Map<String, bool> records; // studentId -> isPresent
  final String topicTaught;

  AttendanceRecordModel({
    required this.id,
    required this.batchId,
    required this.attendanceDate,
    required this.records,
    this.topicTaught = '',
  });

  int get presentCount => records.values.where((v) => v).length;
  int get absentCount => records.values.where((v) => !v).length;
  int get totalCount => records.length;
  double get percentage =>
      totalCount == 0 ? 0.0 : (presentCount / totalCount) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'attendanceDate': attendanceDate.toIso8601String(),
      'records': records,
      'topicTaught': topicTaught,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'attendance_date': attendanceDate.toIso8601String(),
      'records': records,
      'topic_taught': topicTaught,
    };
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    final Map<String, bool> parsedRecords = {};
    if (rawRecords is Map) {
      rawRecords.forEach((key, value) {
        parsedRecords[key.toString()] = value == true;
      });
    }

    return AttendanceRecordModel(
      id: json['id'] as String? ?? '',
      batchId: (json['batchId'] ?? json['batch_id'] ?? '') as String,
      attendanceDate: json['attendanceDate'] != null
          ? (DateTime.tryParse(json['attendanceDate'].toString()) ?? DateTime.now())
          : (json['attendance_date'] != null
              ? (DateTime.tryParse(json['attendance_date'].toString()) ?? DateTime.now())
              : DateTime.now()),
      records: parsedRecords,
      topicTaught: (json['topicTaught'] ?? json['topic_taught'] ?? '') as String,
    );
  }

  factory AttendanceRecordModel.fromSupabaseJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    final Map<String, bool> parsedRecords = {};
    if (rawRecords is Map) {
      rawRecords.forEach((key, value) {
        parsedRecords[key.toString()] = value == true;
      });
    }

    return AttendanceRecordModel(
      id: json['id'] as String? ?? '',
      batchId: (json['batch_id'] ?? json['batchId'] ?? '') as String,
      attendanceDate: json['attendance_date'] != null
          ? (DateTime.tryParse(json['attendance_date'].toString()) ?? DateTime.now())
          : (json['attendanceDate'] != null
              ? (DateTime.tryParse(json['attendanceDate'].toString()) ?? DateTime.now())
              : DateTime.now()),
      records: parsedRecords,
      topicTaught: (json['topic_taught'] ?? json['topicTaught'] ?? '') as String,
    );
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? batchId,
    DateTime? attendanceDate,
    Map<String, bool>? records,
    String? topicTaught,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      records: records ?? this.records,
      topicTaught: topicTaught ?? this.topicTaught,
    );
  }
}
