class Post {
  final String postId;
  final String postTitle;
  final String postGender;
  final String postCity;
  final String postVillage;
  final String postLocation;
  final String postCategory;
  final bool postUserVerified;
  final double postAge;
  final double postPrice;

  // Weight-related fields
  final double postAverageWeight;
  final String? postWeightCategory;
  final double postQuantity;
  final double postWeight;

  // Date stored as Long in Firebase → int in Dart
  final int postDate;

  final bool postIsApproved;
  final List<String> postImages;

  // Post management flags
  final bool postIsFeatured;
  final bool postIsHomePost;
  final bool postIsLiked;
  final bool postIsColored;
  final bool postIsSold;
  final bool postIsTop;
  final bool postIsUpdate;
  final bool postCancelApproved;
  final bool postIsCancelled;

  // NEW FIELDS
  final int postNoLikes;
  final int postLimits;
  final int postIsColoredTimes;
  final int postTopTime;
  final int? postIsHomePostTimes;
  final int? postPutTopTime;

  final int? postIsColoredExpiry;
  final int? postIsTopExpiry;
  final int? postIsHomePostExpiry;
  final int? postIsPutTopExpiry;

  // Category-specific fields
  final String? postAdditionalDetails;
  final double postArea;
  final double postLiquidQuantity;
  final String? postLiveStockCategory;
  final String? postServiceType;
  final String? postBarCode;

  // User-related fields
  final String postUserContact;
  final String postUserId;
  final String postUserImage;
  final String postUserLocation;
  final int postUserLoginDate;
  final String postUserMail;
  final String postUserName;
  final int postViews;
  final String postUserImageColor;

  const Post({
    required this.postId,
    required this.postTitle,
    required this.postGender,
    required this.postCity,
    required this.postVillage,
    required this.postLocation,
    required this.postCategory,
    required this.postUserVerified,
    required this.postAge,
    required this.postPrice,
    required this.postAverageWeight,
    this.postWeightCategory,
    required this.postQuantity,
    required this.postWeight,
    required this.postDate,
    this.postIsApproved = false,
    this.postImages = const [],
    this.postIsFeatured = false,
    this.postIsHomePost = true,
    this.postIsLiked = false,
    this.postIsColored = true,
    this.postIsSold = false,
    this.postIsTop = false,
    this.postIsUpdate = false,
    this.postCancelApproved = false,
    this.postIsCancelled = false,
    this.postAdditionalDetails,
    required this.postArea,
    required this.postLiquidQuantity,
    this.postLiveStockCategory,
    this.postServiceType,
    required this.postBarCode,

    // User-related fields
    required this.postUserContact,
    required this.postUserId,
    required this.postUserImage,
    required this.postUserLocation,
    required this.postUserLoginDate,
    required this.postUserMail,
    required this.postUserName,
    this.postViews = 0,

    // NEW FIELDS
    this.postNoLikes = 0,
    this.postLimits = 0,
    this.postIsColoredTimes = 0,
    this.postTopTime = 0,
    this.postIsHomePostTimes,
    this.postPutTopTime,
    this.postIsColoredExpiry,
    this.postIsTopExpiry,
    this.postIsHomePostExpiry,
    this.postIsPutTopExpiry,
    this.postUserImageColor = '#cccccc',
  });

  /// Display weight intelligently
  String get displayWeight {
    if (postWeight > 0) {
      return '$postWeight KG';
    }
    if (postAverageWeight > 0) {
      String weight = '$postAverageWeight';
      if (postWeightCategory != null && postWeightCategory!.isNotEmpty) {
        weight += ' ($postWeightCategory)';
      }
      return '$weight KG';
    }
    if (postQuantity > 0) {
      return '$postQuantity items';
    }
    return 'N/A';
  }

  /// Factory to build from Firebase map
  factory Post.fromMap(String key, Map<dynamic, dynamic> map) {
    return Post(
      postId: key,
      postTitle: map['postTitle']?.toString() ?? '',
      postGender: map['postGender']?.toString() ?? '',
      postCity: map['postCity']?.toString() ?? '',
      postVillage: map['postVillage']?.toString() ?? '',
      postLocation:
          map['postLocation']?.toString() ??
          map['postUserLocation']?.toString() ??
          '',
      postCategory: map['postCategory']?.toString() ?? '',
      postUserVerified: _parseToBool(map['postUserVerified']) ?? false,
      postAge: _parseToDouble(map['postAge']) ?? 0.0,
      postPrice: _parseToDouble(map['postPrice']) ?? 0.0,
      postAverageWeight: _parseToDouble(map['postAverageWeight']) ?? 0.0,
      postWeightCategory: map['postWeightCategory']?.toString(),
      postQuantity: _parseToDouble(map['postQuantity']) ?? 0.0,
      postWeight: _parseToDouble(map['postWeight']) ?? 0.0,
      postDate:
          _parseToInt(map['postDate']) ?? DateTime.now().millisecondsSinceEpoch,
      postIsApproved: map['postIsApproved'] == true,
      postIsFeatured: map['postIsFeatured'] == true,
      postIsHomePost: map['postIsHomePost'] == true,
      postIsLiked: map['postIsLiked'] == true,
      postIsColored: map['postIsColored'] == true,
      postIsSold: map['postIsSold'] == true,
      postIsTop: map['postIsTop'] == true,
      postIsUpdate: map['postIsUpdate'] == true,
      postCancelApproved: map['postCancelApproved'] == true,
      postIsCancelled: map['postIsCancelled'] == true,
      postImages: _parseImagesList(map['postImages']),
      postAdditionalDetails: map['postAdditionalDetails']?.toString(),
      postArea: _parseToDouble(map['postArea']) ?? 0.0,
      postLiquidQuantity: _parseToDouble(map['postLiquidQuantity']) ?? 0.0,
      postLiveStockCategory: map['postLiveStockCategory']?.toString(),
      postServiceType: map['postServiceType']?.toString(),
      postBarCode: map['postBarCode']?.toString() ?? '',

      // User-related
      postUserContact: map['postUserContact']?.toString() ?? '',
      postUserId: map['postUserId']?.toString() ?? '',
      postUserImage: map['postUserImage']?.toString() ?? '',
      postUserLocation: map['postUserLocation']?.toString() ?? '',
      postUserLoginDate:
          _parseToInt(map['postUserLoginDate']) ??
          DateTime.now().millisecondsSinceEpoch,
      postUserMail: map['postUserMail']?.toString() ?? '',
      postUserName: map['postUserName']?.toString() ?? 'Default',
      postViews: _parseToInt(map['postViews']) ?? 0,

      // NEW FIELDS
      postNoLikes: _parseToInt(map['postNoLikes']) ?? 0,
      postLimits: _parseToInt(map['postLimits']) ?? 0,
      postIsColoredTimes: _parseToInt(map['postIsColoredTimes']) ?? 0,
      postTopTime: _parseToInt(map['postTopTime']) ?? 0,
      postIsHomePostTimes: _parseToInt(map['postIsHomePostTimes']),
      postPutTopTime: _parseToInt(map['postPutTopTime']),
      postIsColoredExpiry: _parseToInt(map['postIsColoredExpiry']),
      postIsTopExpiry: _parseToInt(map['postIsTopExpiry']),
      postIsHomePostExpiry: _parseToInt(map['postIsHomePostExpiry']),
      postIsPutTopExpiry: _parseToInt(map['postIsPutTopExpiry']),
      postUserImageColor: map['postUserImageColor']?.toString() ?? '#ffcccccc',
    );
  }

  /// Convert to Firebase map
  Map<String, dynamic> toMap() {
    return {
      'postTitle': postTitle,
      'postGender': postGender,
      'postCity': postCity,
      'postVillage': postVillage,
      'postLocation': postLocation,
      'postCategory': postCategory,
      'postUserVerified': postUserVerified,
      'postAge': postAge,
      'postPrice': postPrice,
      'postAverageWeight': postAverageWeight,
      'postWeightCategory': postWeightCategory,
      'postQuantity': postQuantity,
      'postWeight': postWeight,
      'postDate': postDate,
      'postIsApproved': postIsApproved,
      'postIsFeatured': postIsFeatured,
      'postIsHomePost': postIsHomePost,
      'postIsLiked': postIsLiked,
      'postIsColored': postIsColored,
      'postIsSold': postIsSold,
      'postIsTop': postIsTop,
      'postIsUpdate': postIsUpdate,
      'postCancelApproved': postCancelApproved,
      'postIsCancelled': postIsCancelled,
      'postImages': postImages,
      'postAdditionalDetails': postAdditionalDetails,
      'postArea': postArea,
      'postLiquidQuantity': postLiquidQuantity,
      'postLiveStockCategory': postLiveStockCategory,
      'postServiceType': postServiceType,
      'postBarCode': postBarCode,

      // User-related
      'postUserContact': postUserContact,
      'postUserId': postUserId,
      'postUserImage': postUserImage,
      'postUserLocation': postUserLocation,
      'postUserLoginDate': postUserLoginDate,
      'postUserMail': postUserMail,
      'postUserName': postUserName,
      'postViews': postViews,

      // NEW FIELDS
      'postNoLikes': postNoLikes,
      'postLimits': postLimits,
      'postIsColoredTimes': postIsColoredTimes,
      'postTopTime': postTopTime,
      'postIsHomePostTimes': postIsHomePostTimes,
      'postPutTopTime': postPutTopTime,
      'postIsColoredExpiry': postIsColoredExpiry,
      'postIsTopExpiry': postIsTopExpiry,
      'postIsHomePostExpiry': postIsHomePostExpiry,
      'postIsPutTopExpiry': postIsPutTopExpiry,
      'postUserImageColor': postUserImageColor,
    };
  }

  /// Safely parse images
  static List<String> _parseImagesList(dynamic value) {
    if (value == null) return [];
    if (value is Map) return value.values.map((e) => e.toString()).toList();
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }

  /// Safely parse int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  /// Safely parse double
  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely parse boolean
  static bool? _parseToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    if (value is int) return value == 1;
    return null;
  }
}
