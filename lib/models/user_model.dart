// models/user_model.dart
class UserModel {
  final String uid;
  final String userName;
  final String userEmail;
  final String dob;
  final String status;
  final String? userScore;
  final bool isVerified;
  final int userLoginDate;
  final String? userFCMToken;
  final String? userContact; // Added userContact field
  final int userPostLimit;
  final int userPostLimitUsed;
  final int userUpdatePostLimit;
  final int userFollowing;
  final int userFollowerBoost;
  final int totalFollowersCount;
  final String? profileColor;
  final String? profileImage;
  final Map<String, dynamic> rawData;

  UserModel({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.dob,
    required this.status,
    this.userScore,
    required this.isVerified,
    required this.userLoginDate,
    this.userFCMToken,
    this.userContact, // Added to constructor
    required this.userPostLimit,
    required this.userPostLimitUsed,
    required this.userUpdatePostLimit,
    required this.userFollowing,
    required this.userFollowerBoost,
    required this.totalFollowersCount,
    this.profileColor,
    this.profileImage,
    required this.rawData,
  });

  /// From backend GET /admin/users row (MySQL users table).
  factory UserModel.fromServerRow(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final email = row['email']?.toString() ?? '';
    final username = row['username']?.toString() ?? 'N/A';
    // isVerified comes from is_subscribed (admin controlled)
    final isVerified = row['isVerified'] == true || row['isVerified'] == 1;
    final createdAt = row['createdAt'];
    int loginDate = 0;
    if (createdAt != null) {
      if (createdAt is int) loginDate = createdAt;
      else if (createdAt is double) loginDate = createdAt.toInt();
      else if (createdAt is String) loginDate = DateTime.tryParse(createdAt)?.millisecondsSinceEpoch ?? 0;
    }
    int parseIntValue(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }
    final userPostLimit = parseIntValue(row['userPostLimit'], fallback: 2);
    final userPostLimitUsed = parseIntValue(row['userPostLimitUsed'], fallback: 0);
    final userUpdatePostLimit = parseIntValue(row['userUpdatePostLimit'], fallback: 0);
    final userFollowing = parseIntValue(row['userFollowing'], fallback: 0);
    final userFollowerBoost = parseIntValue(row['userFollowerBoost'], fallback: 0);
    final actualFollowersCount = parseIntValue(row['actualFollowersCount'], fallback: 0);
    final totalFollowersCount = parseIntValue(row['totalFollowersCount'], fallback: userFollowerBoost);
    final userTotalPostsTime = parseIntValue(row['userTotalPostsTime'], fallback: 30);
    final completeData = Map<String, dynamic>.from(row);
    completeData['uid'] = id;
    completeData['userId'] = id;
    completeData['userName'] = username;
    completeData['userMail'] = email;
    completeData['userIsVerified'] = isVerified;
    completeData['userContact'] = row['phoneComplete'] ?? '';
    completeData['userPostLimit'] = userPostLimit;
    completeData['userPostLimitUsed'] = userPostLimitUsed;
    completeData['userUpdatePostLimit'] = userUpdatePostLimit;
    completeData['userFollowing'] = userFollowing;
    completeData['userFollowerBoost'] = userFollowerBoost;
    completeData['actualFollowersCount'] = actualFollowersCount;
    completeData['totalFollowersCount'] = totalFollowersCount;
    completeData['userTotalPostsTime'] = userTotalPostsTime;
    completeData['userLoginDate'] = loginDate;
    completeData['profileColor'] = row['profile_color'];
    completeData['profileImage'] = row['profile_image'] ?? 'default_pfp.jpg';
    return UserModel(
      uid: id,
      userName: username,
      userEmail: email,
      dob: 'N/A',
      status: isVerified ? 'Verified' : 'Unverified',
      userScore: null,
      isVerified: isVerified,
      rawData: completeData,
      userLoginDate: loginDate,
      userFCMToken: null,
      userContact: row['phoneComplete']?.toString(),
      userPostLimit: userPostLimit,
      userPostLimitUsed: userPostLimitUsed,
      userUpdatePostLimit: userUpdatePostLimit,
      userFollowing: userFollowing,
      userFollowerBoost: userFollowerBoost,
      totalFollowersCount: totalFollowersCount,
      profileColor: row['profile_color']?.toString(),
      profileImage: row['profile_image']?.toString(),
    );
  }

  factory UserModel.fromFirebase(String uid, Map<String, dynamic> data) {
    // Parse DOB
    final dobMap = data['userDOB'] as Map?;
    final dob = dobMap != null
        ? "${dobMap['day']} ${dobMap['month']} ${dobMap['year']}"
        : 'N/A';

    // Determine verification status
    final bool? isVerified = data['userIsVerified'] as bool?;
    final String status = isVerified != null
        ? (isVerified ? 'Verified' : 'Unverified')
        : 'Unverified';

    // Store complete data for editing
    final completeData = Map<String, dynamic>.from(data);
    completeData['uid'] = uid;
    return UserModel(
      uid: data['userId'] ?? uid,
      userName: data['userName'] ?? 'N/A',
      userEmail: data['userMail'] ?? 'N/A',
      dob: dob,
      status: status,
      userScore: data['userScore']?.toString(),
      isVerified: isVerified ?? false,
      rawData: completeData,
      userLoginDate: data['userLoginDate'],
      userFCMToken: data['userFCMToken']?.toString(),
      userContact: data['userContact']?.toString(), // Parse userContact
      userPostLimit: data['userPostLimit'] ?? 0,
      userPostLimitUsed: data['userPostLimitUsed'] ?? 0,
      userUpdatePostLimit: data['userUpdatePostLimit'] ?? 0,
      userFollowing: data['userFollowing'] ?? 0,
      userFollowerBoost: data['userFollowerBoost'] ?? 0,
      totalFollowersCount: data['totalFollowersCount'] ?? (data['userFollowerBoost'] ?? 0),
      profileColor: data['profileColor']?.toString() ?? data['profile_color']?.toString(),
      profileImage: data['profileImage']?.toString() ?? data['profile_image']?.toString(),
    );
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return userName.toLowerCase().contains(lowerQuery) ||
        userEmail.toLowerCase().contains(lowerQuery);
  }

  bool matchesStatus(String? statusFilter) {
    if (statusFilter == null || statusFilter == "All") return true;
    return status.toLowerCase() == statusFilter.toLowerCase();
  }

  bool matchesScore(String? scoreFilter) {
    if (scoreFilter == null || scoreFilter == "All") return true;
    return userScore == scoreFilter;
  }

  Map<String, dynamic> toMap() {
    return rawData;
  }
}
