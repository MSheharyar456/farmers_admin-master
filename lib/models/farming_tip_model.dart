class FarmingTip {
  final String? tipId;
  final String? farmingTipEnglish;
  final String? farmingTipArabic;
  final String? farmingTipGerman;
  final String? farmingTipTurkish;

  FarmingTip({
    this.tipId,
    this.farmingTipEnglish,
    this.farmingTipArabic,
    this.farmingTipGerman,
    this.farmingTipTurkish,
  });

  factory FarmingTip.fromMap(String id, Map<dynamic, dynamic> map) {
    return FarmingTip(
      tipId: id,
      farmingTipEnglish: map['farmingTipEnglish']?.toString(),
      farmingTipArabic: map['farmingTipArabic']?.toString(),
      farmingTipGerman: map['farmingTipGerman']?.toString(),
      farmingTipTurkish: map['farmingTipTurkish']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmingTipEnglish': farmingTipEnglish,
      'farmingTipArabic': farmingTipArabic,
      'farmingTipGerman': farmingTipGerman,
      'farmingTipTurkish': farmingTipTurkish,
    };
  }

  FarmingTip copyWith({
    String? tipId,
    String? farmingTipEnglish,
    String? farmingTipArabic,
    String? farmingTipGerman,
    String? farmingTipTurkish,
  }) {
    return FarmingTip(
      tipId: tipId ?? this.tipId,
      farmingTipEnglish: farmingTipEnglish ?? this.farmingTipEnglish,
      farmingTipArabic: farmingTipArabic ?? this.farmingTipArabic,
      farmingTipGerman: farmingTipGerman ?? this.farmingTipGerman,
      farmingTipTurkish: farmingTipTurkish ?? this.farmingTipTurkish,
    );
  }
}