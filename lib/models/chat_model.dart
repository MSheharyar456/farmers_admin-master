class AdminChatUser {
  final String id;
  final String username;
  final String email;
  final String profileImage;
  final String profileColor;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  AdminChatUser({
    required this.id,
    required this.username,
    required this.email,
    required this.profileImage,
    required this.profileColor,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory AdminChatUser.fromJson(Map<String, dynamic> json) {
    return AdminChatUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? 'default_pfp.jpg',
      profileColor: json['profileColor']?.toString() ?? '#DAD721',
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())?.toLocal()
          : null,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      isOnline: json['isOnline'] == true,
    );
  }

  AdminChatUser copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
  }) {
    return AdminChatUser(
      id: id,
      username: username,
      email: email,
      profileImage: profileImage,
      profileColor: profileColor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class AdminChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message; // Decrypted message
  final bool isRead;
  final DateTime createdAt;

  AdminChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
}
