class WorkingStatus {
  final String? statusId;
  final bool isEnableButton;
  final bool isSomethingWrong;
  final String? workingDetails;
  final String? workingTitle;

  WorkingStatus({
    this.statusId,
    required this.isEnableButton,
    required this.isSomethingWrong,
    this.workingDetails,
    this.workingTitle,
  });

  factory WorkingStatus.fromMap(String id, Map<dynamic, dynamic> map) {
    return WorkingStatus(
      statusId: id,
      isEnableButton: map['isEnableButton'] ?? false,
      isSomethingWrong: map['isSomethingWrong'] ?? false,
      workingDetails: map['workingDetails']?.toString(),
      workingTitle: map['workingTitle']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnableButton': isEnableButton,
      'isSomethingWrong': isSomethingWrong,
      'workingDetails': workingDetails,
      'workingTitle': workingTitle,
    };
  }

  WorkingStatus copyWith({
    String? statusId,
    bool? isEnableButton,
    bool? isSomethingWrong,
    String? workingDetails,
    String? workingTitle,
  }) {
    return WorkingStatus(
      statusId: statusId ?? this.statusId,
      isEnableButton: isEnableButton ?? this.isEnableButton,
      isSomethingWrong: isSomethingWrong ?? this.isSomethingWrong,
      workingDetails: workingDetails ?? this.workingDetails,
      workingTitle: workingTitle ?? this.workingTitle,
    );
  }
}