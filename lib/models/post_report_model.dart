// models/post_report_model.dart
class PostReportModel {
  final String id;
  final String postId;
  final String reporterUserId;
  final String currentUsername;
  final String currentUserMail;
  final String currentUserContact;
  final String postCode;
  final String postRepostAdditionalDetails;
  final int postReportDate;
  final String formattedDate;
  final DateTime? createdAt;

  PostReportModel({
    required this.id,
    required this.postId,
    required this.reporterUserId,
    required this.currentUsername,
    required this.currentUserMail,
    required this.currentUserContact,
    required this.postCode,
    required this.postRepostAdditionalDetails,
    required this.postReportDate,
    required this.formattedDate,
    this.createdAt,
  });

  factory PostReportModel.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['postReportDate'] ?? map['post_report_date'];
    final postReportDate = raw is int
        ? raw
        : (raw is num
            ? (raw as num).toInt()
            : 0);
    final date = DateTime.fromMillisecondsSinceEpoch(postReportDate);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    // Parse created_at if present
    DateTime? createdAt;
    final createdRaw = map['createdAt'] ?? map['created_at'];
    if (createdRaw != null) {
      if (createdRaw is String) {
        createdAt = DateTime.tryParse(createdRaw);
      } else if (createdRaw is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
      }
    }

    return PostReportModel(
      id: map['id']?.toString() ?? id,
      postId: map['postId']?.toString() ?? map['postReportItemId']?.toString() ?? '',
      reporterUserId: map['reporterUserId']?.toString() ?? '',
      currentUsername: map['currentUsername']?.toString() ?? '',
      currentUserMail: map['currentUserMail']?.toString() ?? '',
      currentUserContact: map['currentUserContact']?.toString() ?? '',
      postCode: map['postCode']?.toString() ?? '',
      postRepostAdditionalDetails: map['postRepostAdditionalDetails']?.toString() ?? '',
      postReportDate: postReportDate,
      formattedDate: formattedDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'reporterUserId': reporterUserId,
      'currentUsername': currentUsername,
      'currentUserMail': currentUserMail,
      'currentUserContact': currentUserContact,
      'postCode': postCode,
      'postRepostAdditionalDetails': postRepostAdditionalDetails,
      'postReportDate': postReportDate,
      'formattedDate': formattedDate,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

