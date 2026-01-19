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

