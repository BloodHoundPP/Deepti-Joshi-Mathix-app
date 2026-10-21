class BatchModel {
  final String id;
  final String batchName;
  final String schedule;
  final String instructor;
  final String subject;
  final String standard;
  final int capacity;
  final DateTime createdAt;

  BatchModel({
    required this.id,
    required this.batchName,
    required this.schedule,
    this.instructor = 'Prof. Deepti Joshi',
    this.subject = 'Mathematics',
    this.standard = '10th Standard',
    this.capacity = 25,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchName': batchName,
      'schedule': schedule,
      'instructor': instructor,
      'subject': subject,
      'standard': standard,
      'capacity': capacity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'batch_name': batchName,
      'schedule': schedule,
      'standard': standard,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String? ?? '',
      batchName: (json['batchName'] ?? json['batch_name'] ?? '') as String,
      schedule: json['schedule'] as String? ?? '',
      instructor: json['instructor'] as String? ?? 'Prof. Deepti Joshi',
      subject: json['subject'] as String? ?? 'Mathematics',
      standard: json['standard'] as String? ?? '10th Standard',
      capacity: json['capacity'] as int? ?? 25,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : (json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  factory BatchModel.fromSupabaseJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String? ?? '',
      batchName: (json['batch_name'] ?? json['batchName'] ?? '') as String,
      schedule: json['schedule'] as String? ?? '',
      instructor: json['instructor'] as String? ?? 'Prof. Deepti Joshi',
      subject: json['subject'] as String? ?? 'Mathematics',
      standard: json['standard'] as String? ?? '10th Standard',
      capacity: json['capacity'] as int? ?? 25,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['createdAt'] != null
              ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  BatchModel copyWith({
    String? id,
    String? batchName,
    String? schedule,
    String? instructor,
    String? subject,
    String? standard,
    int? capacity,
    DateTime? createdAt,
  }) {
    return BatchModel(
      id: id ?? this.id,
      batchName: batchName ?? this.batchName,
      schedule: schedule ?? this.schedule,
      instructor: instructor ?? this.instructor,
      subject: subject ?? this.subject,
      standard: standard ?? this.standard,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
