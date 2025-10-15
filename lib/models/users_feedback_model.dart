// models/feedback_model.dart
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final String type;
  final int timestamp;
  final String formattedDate;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.formattedDate,
  });

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['timestamp'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown User',
      message: map['message'] ?? '',
      type: map['type'] ?? 'General',
      timestamp: timestamp,
      formattedDate: formattedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'type': type,
      'timestamp': timestamp,
      'formattedDate': formattedDate,
    };
  }
}
