// models/post_report_model.dart
class PostReportModel {
  final String postReportItemId;
  final String currentUsername;
  final String currentUserMail;
  final String currentUserContact;
  final String postCode;
  final String postRepostAdditionalDetails;
  final int postReportDate;
  final String formattedDate;


  PostReportModel({
    required this.postReportItemId,
    required this.currentUsername,
    required this.currentUserMail,
    required this.currentUserContact,
    required this.postCode,
    required this.postRepostAdditionalDetails,
    required this.postReportDate,
    required this.formattedDate,
  });

  factory PostReportModel.fromMap(String id, Map<String, dynamic> map) {
    final postReportDate = map['postReportDate'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(postReportDate);
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return PostReportModel(
      postReportItemId: map['postReportItemId'] ?? id,
      currentUsername: map['currentUsername'] ?? '',
      currentUserMail: map['currentUserMail'] ?? '',
      currentUserContact: map['currentUserContact'] ?? '',
      postCode: map['postCode'] ?? '',
      postRepostAdditionalDetails: map['postRepostAdditionalDetails'] ?? '',
      postReportDate: postReportDate,
      formattedDate: formattedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postReportItemId': postReportItemId,
      'currentUsername': currentUsername,
      'currentUserMail': currentUserMail,
      'currentUserContact': currentUserContact,
      'postCode': postCode,
      'postRepostAdditionalDetails': postRepostAdditionalDetails,
      'postReportDate': postReportDate,
      'formattedDate': formattedDate,
    };
  }
}

