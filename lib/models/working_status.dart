class WorkingStatus {
  final String? statusId;
  final bool isEnableButton;
  final bool isSomethingWrong;
  final String? workingDetails;
  final String? workingTitle;
  final int? appVersionCode;

  WorkingStatus({
    this.statusId,
    required this.isEnableButton,
    required this.isSomethingWrong,
    this.workingDetails,
    this.workingTitle,
    this.appVersionCode,
  });

  factory WorkingStatus.fromMap(String id, Map<dynamic, dynamic> map) {
    return WorkingStatus(
      statusId: id,
      isEnableButton: map['isEnableButton'] == true || map['isEnableButton'] == 1,
      isSomethingWrong: map['isSomethingWrong'] == true || map['isSomethingWrong'] == 1,
      workingDetails: map['workingDetails']?.toString() ?? map['messageAr']?.toString(),
      workingTitle: map['workingTitle']?.toString() ?? map['messageEn']?.toString(),
      appVersionCode: map['appVersionCode'] != null
          ? int.tryParse(map['appVersionCode'].toString())
          : null,
    );
  }

  /// From backend GET /admin/working-status item.
  factory WorkingStatus.fromServerMap(String id, Map<String, dynamic> map) {
    return WorkingStatus(
      statusId: id,
      isEnableButton: map['isEnableButton'] == true || map['isEnableButton'] == 1,
      isSomethingWrong: map['isSomethingWrong'] == true || map['isSomethingWrong'] == 1,
      workingDetails: map['messageAr']?.toString(),
      workingTitle: map['messageEn']?.toString(),
      appVersionCode: (map['appVersionCode'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnableButton': isEnableButton,
      'isSomethingWrong': isSomethingWrong,
      'workingDetails': workingDetails,
      'workingTitle': workingTitle,
      'appVersionCode': appVersionCode,
    };
  }

  WorkingStatus copyWith({
    String? statusId,
    bool? isEnableButton,
    bool? isSomethingWrong,
    String? workingDetails,
    String? workingTitle,
    int? appVersionCode,
  }) {
    return WorkingStatus(
      statusId: statusId ?? this.statusId,
      isEnableButton: isEnableButton ?? this.isEnableButton,
      isSomethingWrong: isSomethingWrong ?? this.isSomethingWrong,
      workingDetails: workingDetails ?? this.workingDetails,
      workingTitle: workingTitle ?? this.workingTitle,
      appVersionCode: appVersionCode ?? this.appVersionCode,
    );
  }
}
