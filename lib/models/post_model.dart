class Post {
  final String postId;
  final String postTitle;
  final String postGender;
  final String postCity;
  final String postVillage;
  final String postLocation;
  final String postCategory;
  final bool postUserVerified;
  final int postAge;
  final double postPrice;

  // Weight-related fields - handle both old and new structure
  final dynamic postAverageWeight;
  final String? postWeightCategory;
  final int? postQuantity;
  final String? postWeight; // New field for direct weight storage

  // Additional fields to match Firebase structure
  final int? postDate;
  final int? createdAt;
  final int? updatedAt;
  final bool postIsApproved;
  final List<String> postImages;

  // New boolean fields for post management
  final bool postIsFeatured;
  final bool postIsHomePost;
  final bool postIsLiked;
  final bool postIsColored;
  final bool postIsSold;
  final bool postIsTop;
  final bool postIsUpdate;
  final bool postIsCancelled; // ✅ NEW FIELD ADDED

  // Category-specific fields
  final String? postAdditionalDetails;
  final String? postArea; // For irrigation, land services
  final int? postLiquidQuantity; // For olive oils, others
  final String? postLiveStockCategory; // For livestock (cow, sheep, goat, etc.)
  final String? postServiceType; // For equipments, agriculture, etc. (sell/rent)
  final String? postOliveOilType; // For olive&oils (olive/oil/both)
  final String? postFertilizerType; // For fertilizers (organic/chemical/mixed)
  final String? postSystemType; // For irrigation system (drip/sprinkler/surface)

  Post({
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
    this.postAverageWeight,
    this.postWeightCategory,
    this.postQuantity,
    this.postWeight,
    this.postDate,
    this.createdAt,
    this.updatedAt,
    this.postIsApproved = false,
    this.postImages = const [],
    this.postIsFeatured = false,
    this.postIsHomePost = true,
    this.postIsLiked = false,
    this.postIsColored = true,
    this.postIsSold = false,
    this.postIsTop = false,
    this.postIsUpdate = false,
    this.postIsCancelled = false, // ✅ NEW FIELD ADDED
    // Category-specific fields
    this.postAdditionalDetails,
    this.postArea,
    this.postLiquidQuantity,
    this.postLiveStockCategory,
    this.postServiceType,
    this.postOliveOilType,
    this.postFertilizerType,
    this.postSystemType,
  });

  // Computed property to create a display string for weight
  String get displayWeight {
    // Try postWeight first (new structure)
    if (postWeight != null && postWeight!.isNotEmpty && postWeight != '0') {
      return '$postWeight KG';
    }

    // Fallback to postAverageWeight (old structure)
    if (postAverageWeight != null && postAverageWeight.toString().isNotEmpty && postAverageWeight.toString() != '0') {
      String weight = '$postAverageWeight';
      if (postWeightCategory != null && postWeightCategory!.isNotEmpty) {
        weight += ' ($postWeightCategory)';
      }
      return '$weight KG';
    }

    // Fallback to quantity if available
    if (postQuantity != null && postQuantity! > 0) {
      return '$postQuantity items';
    }

    return 'N/A'; // Return N/A if no weight info available
  }

  factory Post.fromMap(String key, Map<dynamic, dynamic> map) {
    return Post(
      postId: key,
      postTitle: map['postTitle']?.toString() ?? '',
      postGender: map['postGender']?.toString() ?? '',
      postCity: map['postCity']?.toString() ?? '',
      postVillage: map['postVillage']?.toString() ?? '',

      // Handle location mapping - check both possible field names
      postLocation: map['postLocation']?.toString() ??
          map['postUserLocation']?.toString() ?? '',

      postCategory: map['postCategory']?.toString() ?? '',
      postUserVerified: map['postUserVerified'] == true,

      // Handle age - convert string to int safely
      postAge: _parseToInt(map['postAge']) ?? 0,

      // Handle price - convert to double safely
      postPrice: _parseToDouble(map['postPrice']) ?? 0.0,

      // Weight fields - handle both structures
      postAverageWeight: map['postAverageWeight'],
      postWeightCategory: map['postWeightCategory']?.toString(),
      postQuantity: _parseToInt(map['postQuantity']),
      postWeight: map['postWeight']?.toString(),

      // Date fields
      postDate: _parseToInt(map['postDate']),
      createdAt: _parseToInt(map['createdAt']),
      updatedAt: _parseToInt(map['updatedAt']),

      // Boolean fields
      postIsApproved: map['postIsApproved'] == true,
      postIsFeatured: map['postIsFeatured'] == true,
      postIsHomePost: map['postIsHomePost'] == true,
      postIsLiked: map['postIsLiked'] == true,
      postIsColored: map['postIsColored'] == true,
      postIsSold: map['postIsSold'] == true,
      postIsTop: map['postIsTop'] == true,
      postIsUpdate: map['postIsUpdate'] == true,
      postIsCancelled: map['postIsCancelled'] == true, // ✅ NEW FIELD ADDED

      // Images field - handle as list with fallback to empty list
      postImages: _parseImagesList(map['postImages']),

      // Category-specific fields
      postAdditionalDetails: map['postAdditionalDetails']?.toString(),
      postArea: map['postArea']?.toString(),
      postLiquidQuantity: _parseToInt(map['postLiquidQuantity']),
      postLiveStockCategory: map['postLiveStockCategory']?.toString(),
      postServiceType: map['postServiceType']?.toString(),
      postOliveOilType: map['postOliveOilType']?.toString(),
      postFertilizerType: map['postFertilizerType']?.toString(),
      postSystemType: map['postSystemType']?.toString(),
    );
  }

  static List<String> _parseImagesList(dynamic value) {
    if (value == null) return [];

    // Case 1: Firebase stores postImages as a Map like { "1": "url1", "2": "url2" }
    if (value is Map) {
      return value.values.map((e) => e.toString()).toList();
    }

    // Case 2: Firebase stores as a List
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    // Case 3: Single string (fallback)
    if (value is String && value.isNotEmpty) {
      return [value];
    }

    return [];
  }

  // Helper method to safely parse integers
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Helper method to safely parse doubles
  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
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
      'postDate': postDate ?? DateTime.now().millisecondsSinceEpoch,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': updatedAt,
      'postIsApproved': postIsApproved,
      'postIsFeatured': postIsFeatured,
      'postIsHomePost': postIsHomePost,
      'postIsLiked': postIsLiked,
      'postIsColored': postIsColored,
      'postIsSold': postIsSold,
      'postIsTop': postIsTop,
      'postIsUpdate': postIsUpdate,
      'postIsCancelled': postIsCancelled, // ✅ NEW FIELD ADDED
      'postImages': postImages,
    };

    // Add category-specific fields only if they're not null
    if (postAdditionalDetails != null) {
      map['postAdditionalDetails'] = postAdditionalDetails;
    }
    if (postArea != null) {
      map['postArea'] = postArea;
    }
    if (postLiquidQuantity != null) {
      map['postLiquidQuantity'] = postLiquidQuantity;
    }
    if (postLiveStockCategory != null) {
      map['postLiveStockCategory'] = postLiveStockCategory;
    }
    if (postServiceType != null) {
      map['postServiceType'] = postServiceType;
    }
    if (postOliveOilType != null) {
      map['postOliveOilType'] = postOliveOilType;
    }
    if (postFertilizerType != null) {
      map['postFertilizerType'] = postFertilizerType;
    }
    if (postSystemType != null) {
      map['postSystemType'] = postSystemType;
    }

    return map;
  }
}