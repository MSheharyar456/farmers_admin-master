// models/commission_model.dart
class CommissionModel {
  final String itemId;
  final String name;
  final String phone;
  final String bank;
  final String commissionAmount;
  final String postCode;
  final String notes;
  final String receiptUrl;
  final int requestData;
  final String formattedDate;

  CommissionModel({
    required this.itemId,
    required this.name,
    required this.phone,
    required this.bank,
    required this.commissionAmount,
    required this.postCode,
    required this.notes,
    required this.receiptUrl,
    required this.requestData,
    required this.formattedDate,
  });

  factory CommissionModel.fromMap(String id, Map<String, dynamic> map) {
    final requestData = map['requestData'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(requestData);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return CommissionModel(
      itemId: map['itemId'] ?? id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      bank: map['bank'] ?? '',
      commissionAmount: map['commissionAmount'] ?? '',
      postCode: map['postCode'] ?? '',
      notes: map['notes'] ?? '',
      receiptUrl: map['receiptUrl'] ?? '',
      requestData: requestData,
      formattedDate: formattedDate,
    );
  }

  /// Parse from backend API response format (GET /admin/commissions)
  factory CommissionModel.fromApiJson(Map<String, dynamic> json) {
    // API returns: id, userId, name, phone, bank, commissionAmount, currency,
    // postCode, notes, receiptUrl, status, adminNotes, requestDate, createdAt
    final id = json['id']?.toString() ?? '';

    // Parse requestDate - can be string or int timestamp
    final requestDateValue = json['requestDate'];
    int requestData = 0;
    if (requestDateValue is int) {
      requestData = requestDateValue;
    } else if (requestDateValue is String) {
      // Try parsing as ISO date string
      try {
        final parsed = DateTime.parse(requestDateValue);
        requestData = parsed.millisecondsSinceEpoch;
      } catch (_) {
        requestData = 0;
      }
    }

    // Parse createdAt as fallback
    if (requestData == 0) {
      final createdAt = json['createdAt'];
      if (createdAt is int) {
        requestData = createdAt;
      } else if (createdAt is String) {
        try {
          final parsed = DateTime.parse(createdAt);
          requestData = parsed.millisecondsSinceEpoch;
        } catch (_) {
          requestData = DateTime.now().millisecondsSinceEpoch;
        }
      } else {
        requestData = DateTime.now().millisecondsSinceEpoch;
      }
    }

    final date = DateTime.fromMillisecondsSinceEpoch(requestData);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return CommissionModel(
      itemId: id,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bank: json['bank']?.toString() ?? '',
      commissionAmount: json['commissionAmount']?.toString() ?? '',
      postCode: json['postCode']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      receiptUrl: json['receiptUrl']?.toString() ?? '',
      requestData: requestData,
      formattedDate: formattedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'phone': phone,
      'bank': bank,
      'commissionAmount': commissionAmount,
      'postCode': postCode,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'requestData': requestData,
      'formattedDate': formattedDate,
    };
  }
}

