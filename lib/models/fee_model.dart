enum FeeStatus {
  paid,
  partial,
  pending;

  String get displayName {
    switch (this) {
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.partial:
        return 'Partial';
      case FeeStatus.pending:
        return 'Pending';
    }
  }

  static FeeStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return FeeStatus.paid;
      case 'partial':
        return FeeStatus.partial;
      default:
        return FeeStatus.pending;
    }
  }
}

class FeeRecordModel {
  final String id;
  final String studentId;
  final String title;
  final String installment;
  final double totalAmount;
  final double paidAmount;
  final FeeStatus status;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String paymentMode;
  final String transactionRef;
  final String receiptNo;

  FeeRecordModel({
    required this.id,
    required this.studentId,
    required this.title,
    this.installment = '1st Installment',
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.dueDate,
    this.paidDate,
    this.paymentMode = 'UPI / GPay',
    this.transactionRef = '',
    this.receiptNo = '',
  });

  double get pendingAmount => (totalAmount - paidAmount).clamp(0.0, totalAmount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'installment': installment,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.name,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paymentMode': paymentMode,
      'transactionRef': transactionRef,
      'receiptNo': receiptNo,
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    final noteParts = <String>[];
    if (transactionRef.isNotEmpty) noteParts.add('Ref: $transactionRef');
    if (receiptNo.isNotEmpty) noteParts.add('Receipt: $receiptNo');
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'installment': installment,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status.name,
      'due_date': dueDate.toIso8601String(),
      'payment_date': paidDate?.toIso8601String(),
      'payment_mode': paymentMode,
      'notes': noteParts.join(' | '),
    };
  }

  factory FeeRecordModel.fromJson(Map<String, dynamic> json) {
    return FeeRecordModel(
      id: json['id'] as String? ?? '',
      studentId: (json['studentId'] ?? json['student_id'] ?? '') as String,
      title: json['title'] as String? ?? 'Tuition Fee',
      installment: json['installment'] as String? ?? '1st Installment',
      totalAmount: (json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] ?? json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: FeeStatus.fromString(json['status'] as String? ?? 'pending'),
      dueDate: json['dueDate'] != null
          ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
          : (json['due_date'] != null
              ? (DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now())
              : DateTime.now()),
      paidDate: json['paidDate'] != null
          ? DateTime.tryParse(json['paidDate'].toString())
          : (json['payment_date'] != null
              ? DateTime.tryParse(json['payment_date'].toString())
              : null),
      paymentMode: (json['paymentMode'] ?? json['payment_mode'] ?? 'UPI / GPay') as String,
      transactionRef: json['transactionRef'] as String? ?? '',
      receiptNo: json['receiptNo'] as String? ?? '',
    );
  }

  factory FeeRecordModel.fromSupabaseJson(Map<String, dynamic> json) {
    String ref = '';
    String rec = '';
    final notes = json['notes'] as String? ?? '';
    if (notes.isNotEmpty) {
      for (final part in notes.split('|')) {
        final trimmed = part.trim();
        if (trimmed.startsWith('Ref:')) {
          ref = trimmed.substring(4).trim();
        } else if (trimmed.startsWith('Receipt:')) {
          rec = trimmed.substring(8).trim();
        }
      }
    }
    return FeeRecordModel(
      id: json['id'] as String? ?? '',
      studentId: (json['student_id'] ?? json['studentId'] ?? '') as String,
      title: json['title'] as String? ?? 'Tuition Fee',
      installment: json['installment'] as String? ?? '1st Installment',
      totalAmount: (json['total_amount'] ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] ?? json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: FeeStatus.fromString(json['status'] as String? ?? 'pending'),
      dueDate: json['due_date'] != null
          ? (DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now())
          : (json['dueDate'] != null
              ? (DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
              : DateTime.now()),
      paidDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString())
          : (json['paidDate'] != null
              ? DateTime.tryParse(json['paidDate'].toString())
              : null),
      paymentMode: (json['payment_mode'] ?? json['paymentMode'] ?? 'UPI / GPay') as String,
      transactionRef: ref.isNotEmpty ? ref : (json['transactionRef'] as String? ?? ''),
      receiptNo: rec.isNotEmpty ? rec : (json['receiptNo'] as String? ?? ''),
    );
  }

  FeeRecordModel copyWith({
    String? id,
    String? studentId,
    String? title,
    String? installment,
    double? totalAmount,
    double? paidAmount,
    FeeStatus? status,
    DateTime? dueDate,
    DateTime? paidDate,
    String? paymentMode,
    String? transactionRef,
    String? receiptNo,
  }) {
    return FeeRecordModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      installment: installment ?? this.installment,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionRef: transactionRef ?? this.transactionRef,
      receiptNo: receiptNo ?? this.receiptNo,
    );
  }
}
