class ChatUser {
  final String userId;
  final String userName;
  final String lastMessage;
  final int lastTime;
  final int unreadCount;

  ChatUser({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map, {int unreadCount = 0}) {
    return ChatUser(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      lastMessage: map['lastMessage'] ?? '',
      lastTime: map['lastTime'] ?? 0,
      unreadCount: unreadCount,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final bool seen;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.seen,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      seen: map['seen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'seen': seen,
    };
  }
}
