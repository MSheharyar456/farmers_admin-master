// models/deleted_user_model.dart
class DeletedUserModel {
  final String uid;
  final String userName;
  final String userEmail;
  final String? phoneCountryCode;
  final String? phoneComplete;
  final String? profileImage;
  final bool isAdmin;
  final bool isActiveSeller;
  final int? createdAt;
  final int? deletedAt;
  final int userPostLimit;
  final int userPostLimitUsed;
  final int userUpdatePostLimit;
  final int userFollowing;
  final int userTotalPostsTime;
  final int? userTotalPostsExpiryTime;
  final Map<String, dynamic> rawData;

  DeletedUserModel({
    required this.uid,
    required this.userName,
    required this.userEmail,
    this.phoneCountryCode,
    this.phoneComplete,
    this.profileImage,
    required this.isAdmin,
    required this.isActiveSeller,
    this.createdAt,
    this.deletedAt,
    required this.userPostLimit,
    required this.userPostLimitUsed,
    required this.userUpdatePostLimit,
    required this.userFollowing,
    required this.userTotalPostsTime,
    this.userTotalPostsExpiryTime,
    required this.rawData,
  });

  factory DeletedUserModel.fromMap(Map<String, dynamic> map) {
    return DeletedUserModel(
      uid: map['id']?.toString() ?? '',
      userName: map['username']?.toString() ?? 'N/A',
      userEmail: map['email']?.toString() ?? '',
      phoneCountryCode: map['phoneCountryCode']?.toString(),
      phoneComplete: map['phoneComplete']?.toString(),
      profileImage: map['profileImage']?.toString(),
      isAdmin: map['isAdmin'] == true || map['isAdmin'] == 1,
      isActiveSeller: map['isActiveSeller'] == true || map['isActiveSeller'] == 1,
      createdAt: map['createdAt'] is int ? map['createdAt'] : null,
      deletedAt: map['deletedAt'] is int ? map['deletedAt'] : null,
      userPostLimit: map['userPostLimit'] ?? 2,
      userPostLimitUsed: map['userPostLimitUsed'] ?? 0,
      userUpdatePostLimit: map['userUpdatePostLimit'] ?? 0,
      userFollowing: map['userFollowing'] ?? 0,
      userTotalPostsTime: map['userTotalPostsTime'] ?? 30,
      userTotalPostsExpiryTime: map['userTotalPostsExpiryTime'] is int ? map['userTotalPostsExpiryTime'] : null,
      rawData: Map<String, dynamic>.from(map),
    );
  }
}

class DeletedUserFullDetails {
  final DeletedUserModel user;
  final DeletedUserStats stats;
  final List<DeletedUserPost> posts;
  final DeletedUserFollows follows;
  final List<DeletedUserCommission> commissions;
  final List<DeletedUserFeedback> feedback;
  final DeletedUserMessages messages;
  final DeletedUserBlocks blocks;
  final List<DeletedUserReport> reports;
  final List<DeletedUserWorkingStatus> workingStatus;

  DeletedUserFullDetails({
    required this.user,
    required this.stats,
    required this.posts,
    required this.follows,
    required this.commissions,
    required this.feedback,
    required this.messages,
    required this.blocks,
    required this.reports,
    required this.workingStatus,
  });

  factory DeletedUserFullDetails.fromMap(Map<String, dynamic> map) {
    return DeletedUserFullDetails(
      user: DeletedUserModel.fromMap(map['user'] ?? {}),
      stats: DeletedUserStats.fromMap(map['stats'] ?? {}),
      posts: (map['posts'] as List<dynamic>? ?? [])
          .map((p) => DeletedUserPost.fromMap(p as Map<String, dynamic>))
          .toList(),
      follows: DeletedUserFollows.fromMap(map['follows'] ?? {}),
      commissions: (map['commissions'] as List<dynamic>? ?? [])
          .map((c) => DeletedUserCommission.fromMap(c as Map<String, dynamic>))
          .toList(),
      feedback: (map['feedback'] as List<dynamic>? ?? [])
          .map((f) => DeletedUserFeedback.fromMap(f as Map<String, dynamic>))
          .toList(),
      messages: DeletedUserMessages.fromMap(map['messages'] ?? {}),
      blocks: DeletedUserBlocks.fromMap(map['blocks'] ?? {}),
      reports: (map['reports'] as List<dynamic>? ?? [])
          .map((r) => DeletedUserReport.fromMap(r as Map<String, dynamic>))
          .toList(),
      workingStatus: (map['workingStatus'] as List<dynamic>? ?? [])
          .map((w) => DeletedUserWorkingStatus.fromMap(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeletedUserStats {
  final int postsCount;
  final int likesGiven;
  final int likesReceived;
  final int viewsReceived;
  final int followingCount;
  final int followersCount;
  final int commissionsCount;
  final int feedbackCount;
  final int messagesSent;
  final int messagesReceived;
  final int blocksGiven;
  final int blocksReceived;
  final int reportsFiled;
  final int workingStatusCount;

  DeletedUserStats({
    required this.postsCount,
    required this.likesGiven,
    required this.likesReceived,
    required this.viewsReceived,
    required this.followingCount,
    required this.followersCount,
    required this.commissionsCount,
    required this.feedbackCount,
    required this.messagesSent,
    required this.messagesReceived,
    required this.blocksGiven,
    required this.blocksReceived,
    required this.reportsFiled,
    required this.workingStatusCount,
  });

  factory DeletedUserStats.fromMap(Map<String, dynamic> map) {
    return DeletedUserStats(
      postsCount: map['postsCount'] ?? 0,
      likesGiven: map['likesGiven'] ?? 0,
      likesReceived: map['likesReceived'] ?? 0,
      viewsReceived: map['viewsReceived'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      followersCount: map['followersCount'] ?? 0,
      commissionsCount: map['commissionsCount'] ?? 0,
      feedbackCount: map['feedbackCount'] ?? 0,
      messagesSent: map['messagesSent'] ?? 0,
      messagesReceived: map['messagesReceived'] ?? 0,
      blocksGiven: map['blocksGiven'] ?? 0,
      blocksReceived: map['blocksReceived'] ?? 0,
      reportsFiled: map['reportsFiled'] ?? 0,
      workingStatusCount: map['workingStatusCount'] ?? 0,
    );
  }
}

class DeletedUserPost {
  final String id;
  final String title;
  final String? description;
  final String? date;
  final String? status;
  final List<String> images;

  DeletedUserPost({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.status,
    required this.images,
  });

  factory DeletedUserPost.fromMap(Map<String, dynamic> map) {
    return DeletedUserPost(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      date: map['date']?.toString(),
      status: map['status']?.toString(),
      images: (map['images'] as List<dynamic>? ?? []).map((i) => i.toString()).toList(),
    );
  }
}

class DeletedUserFollow {
  final String id;
  final String username;
  final String email;
  final String? followedAt;

  DeletedUserFollow({
    required this.id,
    required this.username,
    required this.email,
    this.followedAt,
  });

  factory DeletedUserFollow.fromMap(Map<String, dynamic> map) {
    return DeletedUserFollow(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      followedAt: map['followedAt']?.toString(),
    );
  }
}

class DeletedUserFollows {
  final List<DeletedUserFollow> following;
  final List<DeletedUserFollow> followers;

  DeletedUserFollows({
    required this.following,
    required this.followers,
  });

  factory DeletedUserFollows.fromMap(Map<String, dynamic> map) {
    return DeletedUserFollows(
      following: (map['following'] as List<dynamic>? ?? [])
          .map((f) => DeletedUserFollow.fromMap(f as Map<String, dynamic>))
          .toList(),
      followers: (map['followers'] as List<dynamic>? ?? [])
          .map((f) => DeletedUserFollow.fromMap(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeletedUserCommission {
  final String id;
  final String name;
  final String phone;
  final String bank;
  final String commissionAmount;
  final String? currency;
  final String? postCode;
  final String? status;
  final String? requestDate;
  final String? createdAt;

  DeletedUserCommission({
    required this.id,
    required this.name,
    required this.phone,
    required this.bank,
    required this.commissionAmount,
    this.currency,
    this.postCode,
    this.status,
    this.requestDate,
    this.createdAt,
  });

  factory DeletedUserCommission.fromMap(Map<String, dynamic> map) {
    return DeletedUserCommission(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      bank: map['bank']?.toString() ?? '',
      commissionAmount: map['commissionAmount']?.toString() ?? '',
      currency: map['currency']?.toString(),
      postCode: map['postCode']?.toString(),
      status: map['status']?.toString(),
      requestDate: map['requestDate']?.toString(),
      createdAt: map['createdAt']?.toString(),
    );
  }
}

class DeletedUserFeedback {
  final String id;
  final String? type;
  final String? message;
  final int? rating;
  final String? createdAt;

  DeletedUserFeedback({
    required this.id,
    this.type,
    this.message,
    this.rating,
    this.createdAt,
  });

  factory DeletedUserFeedback.fromMap(Map<String, dynamic> map) {
    return DeletedUserFeedback(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString(),
      message: map['message']?.toString(),
      rating: map['rating'] is int ? map['rating'] : null,
      createdAt: map['createdAt']?.toString(),
    );
  }
}

class DeletedUserConversationPartner {
  final String id;
  final String username;
  final String email;

  DeletedUserConversationPartner({
    required this.id,
    required this.username,
    required this.email,
  });

  factory DeletedUserConversationPartner.fromMap(Map<String, dynamic> map) {
    return DeletedUserConversationPartner(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class DeletedUserMessages {
  final int sent;
  final int received;
  final List<DeletedUserConversationPartner> conversationPartners;

  DeletedUserMessages({
    required this.sent,
    required this.received,
    required this.conversationPartners,
  });

  factory DeletedUserMessages.fromMap(Map<String, dynamic> map) {
    return DeletedUserMessages(
      sent: map['sent'] ?? 0,
      received: map['received'] ?? 0,
      conversationPartners: (map['conversationPartners'] as List<dynamic>? ?? [])
          .map((p) => DeletedUserConversationPartner.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeletedUserBlocks {
  final int given;
  final int received;

  DeletedUserBlocks({
    required this.given,
    required this.received,
  });

  factory DeletedUserBlocks.fromMap(Map<String, dynamic> map) {
    return DeletedUserBlocks(
      given: map['given'] ?? 0,
      received: map['received'] ?? 0,
    );
  }
}

class DeletedUserReport {
  final String id;
  final String? postId;
  final String? postTitle;
  final String? additionalDetails;
  final String? reportDate;

  DeletedUserReport({
    required this.id,
    this.postId,
    this.postTitle,
    this.additionalDetails,
    this.reportDate,
  });

  factory DeletedUserReport.fromMap(Map<String, dynamic> map) {
    return DeletedUserReport(
      id: map['id']?.toString() ?? '',
      postId: map['postId']?.toString(),
      postTitle: map['postTitle']?.toString(),
      additionalDetails: map['additionalDetails']?.toString(),
      reportDate: map['reportDate']?.toString(),
    );
  }
}

class DeletedUserWorkingStatus {
  final String id;
  final String? messageAr;
  final String? messageEn;
  final String? createdAt;

  DeletedUserWorkingStatus({
    required this.id,
    this.messageAr,
    this.messageEn,
    this.createdAt,
  });

  factory DeletedUserWorkingStatus.fromMap(Map<String, dynamic> map) {
    return DeletedUserWorkingStatus(
      id: map['id']?.toString() ?? '',
      messageAr: map['messageAr']?.toString(),
      messageEn: map['messageEn']?.toString(),
      createdAt: map['createdAt']?.toString(),
    );
  }
}
