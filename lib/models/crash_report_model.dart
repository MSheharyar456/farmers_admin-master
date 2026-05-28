class CrashReportModel {
  final int id;
  final String message;
  final String stack;
  final bool fatal;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final String locale;
  final String userId;
  final int createdAt;
  final String formattedDate;

  CrashReportModel({
    required this.id,
    required this.message,
    required this.stack,
    required this.fatal,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.locale,
    required this.userId,
    required this.createdAt,
    required this.formattedDate,
  });

  factory CrashReportModel.fromMap(Map<String, dynamic> map) {
    final createdAt = map['createdAt'] is int
        ? map['createdAt'] as int
        : (map['createdAt'] is num ? (map['createdAt'] as num).toInt() : 0);
    final date = createdAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
        : DateTime.now();
    final formattedDate =
        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return CrashReportModel(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '') ?? 0,
      message: map['message']?.toString() ?? '',
      stack: map['stack']?.toString() ?? '',
      fatal: map['fatal'] == true || map['fatal'] == 1,
      platform: map['platform']?.toString() ?? '',
      appVersion: map['appVersion']?.toString() ?? '',
      buildNumber: map['buildNumber']?.toString() ?? '',
      locale: map['locale']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      createdAt: createdAt,
      formattedDate: formattedDate,
    );
  }

  String get versionLabel {
    if (appVersion.isEmpty && buildNumber.isEmpty) return '—';
    if (buildNumber.isEmpty) return appVersion;
    return '$appVersion ($buildNumber)';
  }

  String get shortMessage {
    if (message.length <= 80) return message;
    return '${message.substring(0, 80)}…';
  }

  String get shortUserId {
    if (userId.isEmpty) return '—';
    if (userId.length <= 12) return userId;
    return '${userId.substring(0, 8)}…';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'message': message,
        'stack': stack,
        'fatal': fatal,
        'platform': platform,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'locale': locale,
        'userId': userId,
        'createdAt': createdAt,
        'formattedDate': formattedDate,
      };
}
