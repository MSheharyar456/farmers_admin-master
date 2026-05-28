// models/feedback_model.dart
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final String type;
  final int timestamp;
  final String formattedDate;
  final String? userMail;
  final String? userContact;
  final int? rating;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.formattedDate,
    this.userMail,
    this.userContact,
    this.rating,
  });

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['timestamp'] is int
        ? map['timestamp'] as int
        : (map['timestamp'] is num
            ? (map['timestamp'] as num).toInt()
            : 0);
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return FeedbackModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'Unknown User',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'General',
      timestamp: timestamp,
      formattedDate: formattedDate,
      userMail: map['userMail']?.toString(),
      userContact: map['userContact']?.toString(),
      rating: map['rating'] is int ? map['rating'] : null,
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
      'userMail': userMail,
      'userContact': userContact,
      'rating': rating,
    };
  }
}
