class UserNotification {
  final String notificationId;
  final int notificationDate;
  final String notificationMessage;
  final String notificationTitle;
  final String userId;

  UserNotification({
    required this.notificationId,
    required this.notificationDate,
    required this.notificationMessage,
    required this.notificationTitle,
    required this.userId,
  });

  factory UserNotification.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserNotification(
      notificationId: id,
      notificationDate: map['notificationDate'] as int? ?? 
                       DateTime.now().millisecondsSinceEpoch,
      notificationMessage: map['notificationMessage']?.toString() ?? '',
      notificationTitle: map['notificationTitle']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'notificationDate': notificationDate,
      'notificationMessage': notificationMessage,
      'notificationTitle': notificationTitle,
      'userId': userId,
    };
  }

  UserNotification copyWith({
    String? notificationId,
    int? notificationDate,
    String? notificationMessage,
    String? notificationTitle,
    String? userId,
  }) {
    return UserNotification(
      notificationId: notificationId ?? this.notificationId,
      notificationDate: notificationDate ?? this.notificationDate,
      notificationMessage: notificationMessage ?? this.notificationMessage,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      userId: userId ?? this.userId,
    );
  }
}

