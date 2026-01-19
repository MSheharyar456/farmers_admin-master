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
  final int userUpdatePostLimit;
  final int userFollowing;
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
    required this.userUpdatePostLimit,
    required this.userFollowing,
    required this.rawData,
  });

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
      userUpdatePostLimit: data['userUpdatePostLimit'] ?? 0,
      userFollowing: data['userFollowing'] ?? 0,
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
