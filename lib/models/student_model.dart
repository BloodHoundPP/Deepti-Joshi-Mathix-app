class StudentModel {
  final String id;
  final String fullName;
  final String phone;
  final String parentPhone;
  final String address;
  final String batchId;
  final String email;
  final String rollNo;
  final DateTime joinDate;
  final String school;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.parentPhone,
    required this.address,
    required this.batchId,
    this.email = '',
    this.rollNo = '',
    DateTime? joinDate,
    this.school = '',
  }) : joinDate = joinDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'parentPhone': parentPhone,
      'address': address,
      'batchId': batchId,
      'email': email,
      'rollNo': rollNo,
      'joinDate': joinDate.toIso8601String(),
      'school': school,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'parent_phone': parentPhone,
      'address': address,
      'batch_id': batchId,
      'email': email,
      'school': school,
      'created_at': joinDate.toIso8601String(),
    };
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String? ?? '',
      fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
      phone: json['phone'] as String? ?? '',
      parentPhone: (json['parentPhone'] ?? json['parent_phone'] ?? '') as String,
      address: json['address'] as String? ?? '',
      batchId: (json['batchId'] ?? json['batch_id'] ?? '') as String,
      email: json['email'] as String? ?? '',
      rollNo: (json['rollNo'] ?? json['roll_no'] ?? '') as String,
      joinDate: json['joinDate'] != null
          ? (DateTime.tryParse(json['joinDate'].toString()) ?? DateTime.now())
          : (json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      school: json['school'] as String? ?? '',
    );
  }

  factory StudentModel.fromSupabaseJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName'] ?? '') as String,
      phone: json['phone'] as String? ?? '',
      parentPhone: (json['parent_phone'] ?? json['parentPhone'] ?? '') as String,
      address: json['address'] as String? ?? '',
      batchId: (json['batch_id'] ?? json['batchId'] ?? '') as String,
      email: json['email'] as String? ?? '',
      rollNo: (json['roll_no'] ?? json['rollNo'] ?? '') as String,
      joinDate: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['joinDate'] != null
              ? (DateTime.tryParse(json['joinDate'].toString()) ?? DateTime.now())
              : DateTime.now()),
      school: json['school'] as String? ?? '',
    );
  }

  StudentModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? parentPhone,
    String? address,
    String? batchId,
    String? email,
    String? rollNo,
    DateTime? joinDate,
    String? school,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      address: address ?? this.address,
      batchId: batchId ?? this.batchId,
      email: email ?? this.email,
      rollNo: rollNo ?? this.rollNo,
      joinDate: joinDate ?? this.joinDate,
      school: school ?? this.school,
    );
  }
}
