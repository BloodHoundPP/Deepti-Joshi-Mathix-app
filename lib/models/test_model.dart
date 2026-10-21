class TestModel {
  final String id;
  final String testTitle;
  final String subject;
  final String chapter;
  final String batchId;
  final int totalMarks;
  final int passingMarks;
  final DateTime testDate;

  TestModel({
    required this.id,
    required this.testTitle,
    required this.subject,
    required this.chapter,
    required this.batchId,
    required this.totalMarks,
    required this.passingMarks,
    required this.testDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testTitle': testTitle,
      'subject': subject,
      'chapter': chapter,
      'batchId': batchId,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'testDate': testDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'test_title': testTitle,
      'chapter': chapter,
      'batch_id': batchId,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'test_date': testDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String? ?? '',
      testTitle: (json['testTitle'] ?? json['test_title'] ?? '') as String,
      subject: json['subject'] as String? ?? 'Mathematics',
      chapter: json['chapter'] as String? ?? '',
      batchId: (json['batchId'] ?? json['batch_id'] ?? '') as String,
      totalMarks: (json['totalMarks'] ?? json['total_marks'] as num?)?.toInt() ?? 100,
      passingMarks: (json['passingMarks'] ?? json['passing_marks'] as num?)?.toInt() ?? 40,
      testDate: json['testDate'] != null
          ? (DateTime.tryParse(json['testDate'].toString()) ?? DateTime.now())
          : (json['test_date'] != null
              ? (DateTime.tryParse(json['test_date'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  factory TestModel.fromSupabaseJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String? ?? '',
      testTitle: (json['test_title'] ?? json['testTitle'] ?? '') as String,
      subject: json['subject'] as String? ?? 'Mathematics',
      chapter: json['chapter'] as String? ?? '',
      batchId: (json['batch_id'] ?? json['batchId'] ?? '') as String,
      totalMarks: (json['total_marks'] ?? json['totalMarks'] as num?)?.toInt() ?? 100,
      passingMarks: (json['passing_marks'] ?? json['passingMarks'] as num?)?.toInt() ?? 40,
      testDate: json['test_date'] != null
          ? (DateTime.tryParse(json['test_date'].toString()) ?? DateTime.now())
          : (json['testDate'] != null
              ? (DateTime.tryParse(json['testDate'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  TestModel copyWith({
    String? id,
    String? testTitle,
    String? subject,
    String? chapter,
    String? batchId,
    int? totalMarks,
    int? passingMarks,
    DateTime? testDate,
  }) {
    return TestModel(
      id: id ?? this.id,
      testTitle: testTitle ?? this.testTitle,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      batchId: batchId ?? this.batchId,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      testDate: testDate ?? this.testDate,
    );
  }
}

class StudentTestMarkModel {
  final String id;
  final String testId;
  final String studentId;
  final double marksObtained;
  final String remarks;

  StudentTestMarkModel({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.marksObtained,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'studentId': studentId,
      'marksObtained': marksObtained,
      'remarks': remarks,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'test_id': testId,
      'student_id': studentId,
      'marks_obtained': marksObtained,
      'remarks': remarks,
    };
  }

  factory StudentTestMarkModel.fromJson(Map<String, dynamic> json) {
    return StudentTestMarkModel(
      id: json['id'] as String? ?? '',
      testId: (json['testId'] ?? json['test_id'] ?? '') as String,
      studentId: (json['studentId'] ?? json['student_id'] ?? '') as String,
      marksObtained: (json['marksObtained'] ?? json['marks_obtained'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String? ?? '',
    );
  }

  factory StudentTestMarkModel.fromSupabaseJson(Map<String, dynamic> json) {
    return StudentTestMarkModel(
      id: json['id'] as String? ?? '',
      testId: (json['test_id'] ?? json['testId'] ?? '') as String,
      studentId: (json['student_id'] ?? json['studentId'] ?? '') as String,
      marksObtained: (json['marks_obtained'] ?? json['marksObtained'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String? ?? '',
    );
  }

  StudentTestMarkModel copyWith({
    String? id,
    String? testId,
    String? studentId,
    double? marksObtained,
    String? remarks,
  }) {
    return StudentTestMarkModel(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      studentId: studentId ?? this.studentId,
      marksObtained: marksObtained ?? this.marksObtained,
      remarks: remarks ?? this.remarks,
    );
  }
}
