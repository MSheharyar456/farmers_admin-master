class FarmingTip {
  final String? tipId;
  final String? farmingTipEnglish;
  final String? farmingTipArabic;
  final String? farmingTipGerman;
  final String? farmingTipTurkish;
  final int? createdAt;

  FarmingTip({
    this.tipId,
    this.farmingTipEnglish,
    this.farmingTipArabic,
    this.farmingTipGerman,
    this.farmingTipTurkish,
    this.createdAt,
  });

  factory FarmingTip.fromMap(String id, Map<dynamic, dynamic> map) {
    return FarmingTip(
      tipId: id,
      farmingTipEnglish: map['farmingTipEnglish']?.toString(),
      farmingTipArabic: map['farmingTipArabic']?.toString(),
      farmingTipGerman: map['farmingTipGerman']?.toString(),
      farmingTipTurkish: map['farmingTipTurkish']?.toString(),
      createdAt: map['createdAt'] as int? ?? 
                map['timestamp'] as int? ?? // fallback to timestamp if createdAt doesn't exist
                0, // default to 0 if neither exists
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmingTipEnglish': farmingTipEnglish,
      'farmingTipArabic': farmingTipArabic,
      'farmingTipGerman': farmingTipGerman,
      'farmingTipTurkish': farmingTipTurkish,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  FarmingTip copyWith({
    String? tipId,
    String? farmingTipEnglish,
    String? farmingTipArabic,
    String? farmingTipGerman,
    String? farmingTipTurkish,
    int? createdAt,
  }) {
    return FarmingTip(
      tipId: tipId ?? this.tipId,
      farmingTipEnglish: farmingTipEnglish ?? this.farmingTipEnglish,
      farmingTipArabic: farmingTipArabic ?? this.farmingTipArabic,
      farmingTipGerman: farmingTipGerman ?? this.farmingTipGerman,
      farmingTipTurkish: farmingTipTurkish ?? this.farmingTipTurkish,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}