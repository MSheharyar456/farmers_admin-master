import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart' hide SideMenu;
import 'package:farmers_admin/widgets/cancel_request.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  final String? sourceScreen;
  const EditPostScreen({super.key, required this.post, this.sourceScreen});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}


class _EditPostScreenState extends State<EditPostScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: EditPostContent(
        post: widget.post,
        sourceScreen: widget.sourceScreen,
      ),
    );
  }
}


class EditPostContent extends StatefulWidget {
  final Post post;
  final String? sourceScreen;
  const EditPostContent({super.key, required this.post, this.sourceScreen});

  @override
  State<EditPostContent> createState() => _EditPostContentState();
}

class _EditPostContentState extends State<EditPostContent> {
  final ActivityLogService _activityLogService = ActivityLogService.instance;
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'productsPostData',
  );

  // Helper method to format display text
  String _formatDisplayText(String text) {
    if (text.isEmpty) return text;

    // Handle specific cases
    final specialCases = {
      'grain_seeds': 'Grains & Seeds',
      'olive_oil': 'Olive Oil',
      'animalsFeed': 'Animals Feed',
      'agriculturalTools': 'Agricultural Tools',
      'landServices': 'Land Services',
      'workerServices': 'Worker Services',
      'live_stock': 'Live Stock',
      'leafyGreen': 'Leafy Green',
      'byKg': 'By KG',
      'byBox': 'By Box',
    };

    // Check if it's a special case
    if (specialCases.containsKey(text)) {
      return specialCases[text]!;
    }

    // Convert camelCase or snake_case to Title Case
    String result = text
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .trim();

    // Capitalize first letter of each word
    return result
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Helper method to get formatted categories for display
  List<DropdownMenuItem<String>> _getCategoryDropdownItems() {
    return _categories
        .map(
          (cat) => DropdownMenuItem(
            value: cat,
            child: Text(
              _formatDisplayText(cat),
              style: TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList();
  }

  // Helper method to get formatted items for any dropdown
  List<DropdownMenuItem<String>> _getFormattedDropdownItems(
    List<String> items,
  ) {
    return items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(
              _formatDisplayText(item),
              style: TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList();
  }

  // Helper method to format login date from int timestamp to readable string
  String _formatLoginDate(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "N/A";
    }
  }

  // Helper method to safely get postTopTime as int (handles old cached Post objects with String)
  int _safeGetPostTopTime(Post post) {
    try {
      // Access the value dynamically to handle both old (String) and new (int) types
      final value = (post as dynamic).postTopTime;
      if (value is int) {
        return value;
      } else if (value is String) {
        // Handle old cached Post objects where postTopTime was a String
        return int.tryParse(value.trim()) ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      // Fallback to 0 if anything goes wrong
      return 0;
    }
  }

  // Helper method to get initials from name (first letter, or first letter of both words if two words)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final trimmed = name.trim();
    final words = trimmed.split(' ').where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return '?';
    if (words.length == 1) {
      // For single word, return first two letters if available
      final word = words[0];
      if (word.length >= 2) {
        return '${word[0].toUpperCase()}${word[1].toUpperCase()}';
      } else {
        return word[0].toUpperCase();
      }
    }
    // Two or more words: take first letter of first two words
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }

  // Helper method to parse hex color from string (format: #123456 or 123456)
  Color _parseHexColor(String hexString) {
    try {
      String hex = hexString.trim();
      // Remove # if present
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      // If hex is valid, parse it
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return Color.fromRGBO(r, g, b, 1.0);
      }
    } catch (e) {
      // If parsing fails, return default grey
    }
    return Colors.grey[300]!;
  }

  // Common Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _cityController;
  late final TextEditingController _villageController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _additionalDetailsController;

  // Category Specific Controllers
  late final TextEditingController _quantityController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;
  late final TextEditingController _areaController;
  late final TextEditingController _averageWeightController;
  late final TextEditingController _liquidQuantityController;

  // User Information Controllers
  late final TextEditingController _userContactController;
  late final TextEditingController _userIdController;
  late final TextEditingController _userImageController;
  late final TextEditingController _userLocationController;
  late final TextEditingController _postUserLoginController;
  late final TextEditingController _userMailController;
  late final TextEditingController _userNameController;
  late final TextEditingController _viewsController;

  // NEW: Controllers for new fields
  late final TextEditingController _postNoLikesController;
  late final TextEditingController _postLimitsController;
  late final TextEditingController _postIsColoredTimesController;
  late final TextEditingController _postTopTimeController;

  late String? _category;
  late String _gender;
  late String _weightCategory;
  late String _liveStockCategory;
  late String _serviceType;
  late String _quantityUnit;
  String? _postCurrencyCategory;

  late bool _isCancelled;
  int _selectedIndex = 1;
  bool _isLoading = false;

  // Boolean fields
  late bool _isApproved;
  late bool _isFeatured;
  late bool _isHomePost;
  late bool _isLiked;
  late bool _isSold;
  late bool _isTop;
  late bool _isUpdate;
  late bool _userVerified;
  late bool _isPostColored;

  bool _showCancelDialog = false;

  // Organized category list matching AddPostScreen
  final List<String> _categories = [
    "fruits",
    "vegetables",
    "jam",
    "pomegranate",
    "apples",
    "honey",
    "grain_seeds",
    "fertilizers",
    "animalsFeed",
    "cheese",
    "leafyGreen",
    "olive_oil",
    "pesticides",
    "agriculturalTools",
    "delivery",
    "equipments",
    "landServices",
    "workerServices",
    "irrigation",
    "live_stock",
    "others",
  ];

  @override
  void initState() {
    super.initState();
    final post = widget.post;

    // Initialize common controllers
    _titleController = TextEditingController(text: post.postTitle);
    _cityController = TextEditingController(text: post.postCity);
    _villageController = TextEditingController(text: post.postVillage);
    _priceController = TextEditingController(
      text: post.postPrice?.toString() ?? '',
    );
    _locationController = TextEditingController(text: post.postLocation ?? '');
    _additionalDetailsController = TextEditingController(
      text: post.postAdditionalDetails ?? '',
    );

    // Initialize category-specific controllers
    _quantityController = TextEditingController(
      text: post.postQuantity?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: post.postWeight?.toString() ?? '',
    );
    _ageController = TextEditingController(
      text: post.postAge?.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: post.postArea?.toString() ?? '',
    );
    _averageWeightController = TextEditingController(
      text:
          (post.postWeightCategory == "byKg" ||
              post.postCategory == "grain_seeds" ||
              post.postCategory == "cheese" ||
              post.postCategory == "fruits" ||
              post.postCategory == "fertilizers" ||
              post.postCategory == "animalsFeed" ||
              post.postCategory == "jam" ||
              post.postCategory == "honey" ||
              post.postCategory == "pomegranate" ||
              post.postCategory == "apples")
          ? (post.postAverageWeight?.toString() ?? '')
          : '',
    );
    _liquidQuantityController = TextEditingController(
      text: post.postLiquidQuantity?.toString() ?? '',
    );

    // Initialize user information controllers
    _userContactController = TextEditingController(text: post.postUserContact);
    _userIdController = TextEditingController(text: post.postUserId);
    _userImageController = TextEditingController(text: post.postUserImage);
    _userLocationController = TextEditingController(
      text: post.postUserLocation,
    );
    _postUserLoginController = TextEditingController(
      text: _formatLoginDate(post.postUserLoginDate),
    );

    _userMailController = TextEditingController(text: post.postUserMail);
    _userNameController = TextEditingController(text: post.postUserName);
    _viewsController = TextEditingController(text: post.postViews.toString());

    // NEW: Initialize new field controllers
    _postNoLikesController = TextEditingController(
      text: post.postNoLikes?.toString() ?? '0',
    );
    _postLimitsController = TextEditingController(
      text: post.postLimits?.toString() ?? '0',
    );
    _postIsColoredTimesController = TextEditingController(
      text: post.postIsColoredTimes?.toString() ?? '0',
    );
    _postTopTimeController = TextEditingController(
      text: _safeGetPostTopTime(post).toString(),
    );

    // Initialize category
    _category = _categories.contains(post.postCategory)
        ? post.postCategory
        : null;

    // Initialize category-specific dropdowns with safe defaults
    _gender = post.postGender ?? "male";
    _weightCategory = post.postWeightCategory ?? "byKg";
    _liveStockCategory = post.postLiveStockCategory ?? "cow";
    _serviceType = post.postServiceType ?? "sell";
    _quantityUnit = post.postWeightCategory ?? "SelectedCategory";
    _isCancelled = post.postCancelApproved ?? false;

    // Initialize boolean fields
    _isApproved = post.postIsApproved;
    _isFeatured = post.postIsFeatured ?? false;
    _isHomePost = post.postIsHomePost ?? true;
    _isLiked = post.postIsLiked ?? false;
    _isSold = post.postIsSold ?? false;
    _isTop = post.postIsTop ?? false;
    _isUpdate = post.postIsUpdate ?? false;
    _userVerified = post.postUserVerified ?? false;
    _isPostColored = post.postIsColored ?? true;

    // Fetch currency category from Firebase
    _loadCurrencyCategory();
  }

  Future<void> _loadCurrencyCategory() async {
    try {
      final snapshot = await _dbRef
          .child(widget.post.postId)
          .child('postCurrencyCategory')
          .get();
      if (snapshot.exists && mounted) {
        setState(() {
          _postCurrencyCategory = snapshot.value?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading currency category: $e');
    }
  }

  void _copyToClipboard(String text, {String? label}) {
    if (text.isEmpty) return;
    try {
      Clipboard.setData(ClipboardData(text: text));
      final message = label != null ? '$label copied' : 'Copied to clipboard';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _category = newCategory;
      // Clear all category-specific controllers
      _quantityController.clear();
      _weightController.clear();
      _ageController.clear();
      _areaController.clear();
      _averageWeightController.clear();
      _liquidQuantityController.clear();

      // Reset dropdowns to category-appropriate defaults
      _gender = "male";
      _weightCategory = "byKg";
      _liveStockCategory = "cow";

      // Set appropriate service type based on category
      if (newCategory == "workerServices") {
        _serviceType = "daily";
      } else if (newCategory == "irrigation") {
        _serviceType = "sell";
      } else {
        _serviceType = "sell";
      }
    });
  }

  Future<void> _cancelPostRequest() async {
    await showCancelRequestDialog(
      context: context,
      title: 'Cancel Post Request?',
      message:
          'Are you sure you want to cancel this post request? This action will mark the post as cancelled.',
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          await _dbRef
              .child(widget.post.postId)
              .update({
                'postCancelApproved': true,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              })
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw Exception('Connection timeout');
                },
              );

          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _isCancelled = true;
          });

          // Show success snackbar before navigating
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Post request cancelled successfully"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (snackbarError) {
              debugPrint('Error showing success snackbar: $snackbarError');
            }
          }

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to cancel post: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );

          debugPrint('Error cancelling post: $e');
        }
      },
    );
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please fix the validation errors before updating"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          debugPrint('Error showing validation snackbar: $e');
        }
      }
      return;
    }

    // If post is approved, set cancelled to false
    bool updatedCancelled = _isCancelled;
    if (_isApproved) {
      updatedCancelled = false;
    }

    setState(() {
      _isLoading = true;
      _isCancelled = updatedCancelled;
    });

    try {
      // Base post data
      Map<String, dynamic> postData = {
        "postCancelApproved": _isCancelled,
        "postTitle": _titleController.text.trim(),
        "postCity": _cityController.text.trim(),
        "postVillage": _villageController.text.trim(),
        "postPrice": double.tryParse(_priceController.text.trim()) ?? 0,
        "postUserLocation": _locationController.text.trim(),
        "postAdditionalDetails": _additionalDetailsController.text.trim(),
        "postCategory": _category ?? "others",
        "postIsApproved": _isApproved,
        "postIsFeatured": _isFeatured,
        "postIsHomePost": _isHomePost,
        "postIsLiked": _isLiked,
        "postIsColored": _isPostColored,
        "postIsSold": _isSold,
        "postIsTop": _isTop,
        "postUserVerified": _userVerified,

        // User information fields
        "postUserContact": _userContactController.text.trim(),
        "postUserId": _userIdController.text.trim(),
        "postUserImage": _userImageController.text.trim(),
        "postUserMail": _userMailController.text.trim(),
        "postUserName": _userNameController.text.trim(),
        "postViews": int.tryParse(_viewsController.text.trim()) ?? 0,

        // NEW: Add new fields to postData
        "postNoLikes": int.tryParse(_postNoLikesController.text.trim()) ?? 0,
        "postLimits": int.tryParse(_postLimitsController.text.trim()) ?? 0,
        "postIsColoredTimes":
            int.tryParse(_postIsColoredTimesController.text.trim()) ?? 0,
        "postTopTime": int.tryParse(_postTopTimeController.text.trim()) ?? 0,
      };

      // Add category-specific fields based on organized groups
      switch (_category) {
        case "fruits":
        case "vegetables":
        case "jam":
        case "pomegranate":
        case "apples":
        case "honey":
          if (_weightCategory == "byKg") {
            if (_averageWeightController.text.isNotEmpty) {
              postData["postAverageWeight"] =
                  double.tryParse(_averageWeightController.text) ?? 0;
            }
          } else {
            if (_quantityController.text.isNotEmpty) {
              postData["postQuantity"] =
                  double.tryParse(_quantityController.text) ?? 0;
            }
          }
          postData["postWeightCategory"] = _weightCategory;
          break;

        case "grain_seeds":
        case "fertilizers":
        case "animalsFeed":
        case "cheese":
        case "leafyGreen":
          if (_averageWeightController.text.isNotEmpty) {
            postData["postAverageWeight"] =
                double.tryParse(_averageWeightController.text) ?? 0;
          }
          break;

        case "olive_oil":
        case "pesticides":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] =
                double.tryParse(_liquidQuantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _quantityUnit;
          break;

        case "agriculturalTools":
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] =
                double.tryParse(_quantityController.text) ?? 0;
          }
          postData["postServiceType"] = _serviceType;
          break;

        case "delivery":
          postData["postServiceType"] = _serviceType;
          break;

        case "equipments":
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] =
                double.tryParse(_quantityController.text) ?? 0;
          }
          postData["postServiceType"] = _serviceType;
          break;

        case "landServices":
          postData["postServiceType"] = _serviceType;
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = double.tryParse(_areaController.text.trim());
          }
          break;

        case "workerServices":
          postData["postGender"] = _gender;
          postData["postQuantity"] = double.tryParse(
            _quantityController.text.trim(),
          );
          postData["postAge"] = double.tryParse(_ageController.text.trim());
          break;

        case "irrigation":
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = double.tryParse(_areaController.text.trim());
          }
          postData["postServiceType"] = _serviceType;
          break;

        case "live_stock":
          postData["postLiveStockCategory"] = _liveStockCategory;
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] =
                double.tryParse(_quantityController.text) ?? 0;
          }
          postData["postGender"] = _gender;
          if (_ageController.text.isNotEmpty) {
            postData["postAge"] = double.tryParse(_ageController.text) ?? 0;
          }
          break;

        case "others":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] =
                double.tryParse(_liquidQuantityController.text) ?? 0;
          }
          break;
      }

      await _dbRef
          .child(widget.post.postId)
          .update(postData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );
      await _activityLogService.logCrudAction(
        resource: 'productsPostData',
        action: 'update',
        description:
            'Updated post ${widget.post.postTitle ?? widget.post.postId}',
        targetId: widget.post.postId,
        metadata: {
          'postId': widget.post.postId,
          'postTitle': widget.post.postTitle,
          'category': _category,
          'approved': _isApproved,
          'cancelled': _isCancelled,
        },
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success snackbar before navigating
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Post updated successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (snackbarError) {
          debugPrint('Error showing success snackbar: $snackbarError');
        }
      }

      // Wait a bit for user to see the snackbar, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, 'success');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error snackbar with try-catch to prevent deactivated widget errors
      if (mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update post: ${e.toString()}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (snackbarError) {
          debugPrint('Error showing error snackbar: $snackbarError');
        }
      }

      debugPrint('Error updating post: $e');
    }
  }

  Widget _buildTextField2({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),

        TextFormField(
          style: TextStyle(fontSize: 12),
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: 9,
          expands: false,
          validator: validator,
          enabled: enabled && !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(color: Colors.green, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 21,
            ),
            suffixIcon: suffixIcon,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField3({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 38,
          child: TextFormField(
            style: TextStyle(fontSize: 12),

            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled && !_isLoading,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 38,
          child: TextFormField(
            style: TextStyle(fontSize: 12),
            readOnly: true,
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled && !_isLoading,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField1({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 38,
          child: TextFormField(
            readOnly: true,
            style: TextStyle(fontSize: 12),
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled && !_isLoading,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            style: TextStyle(fontSize: 10),
            value: value,
            onChanged: _isLoading ? null : onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.black,
            ),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.green, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 12,
              ),
            ),
            items: _getFormattedDropdownItems(items),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdownField() {
    // Currency options mapping: Firebase value -> Display name
    final currencyOptions = {
      'ل س': 'Syria(ل س)',
      '\$': 'USD(\$)',
      '€': 'Euro(€)',
      '₺': 'Lira(₺)',
    };

    // Get current currency value and normalize it (trim whitespace)
    String? rawValue = _postCurrencyCategory;
    String normalizedValue = 'ل س'; // Default

    if (rawValue != null && rawValue.isNotEmpty) {
      String trimmed = rawValue.trim();
      // Check if the trimmed value matches any key in currencyOptions
      if (currencyOptions.containsKey(trimmed)) {
        normalizedValue = trimmed;
      } else {
        // Try to match with different variations (handle trailing spaces)
        for (String key in currencyOptions.keys) {
          if (trimmed == key ||
              trimmed.startsWith(key) ||
              key.startsWith(trimmed)) {
            normalizedValue = key;
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Currency",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            value: normalizedValue,
            onChanged: null, // Disabled - read only
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.black,
            ),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: currencyOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 50,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? Colors.green : Colors.grey[300],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: value ? 10 : null,
                    right: value ? null : 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        value ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: value ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: value ? 30 : 5,
                    top: 3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySpecificFields() {
    if (_category == null) return const SizedBox.shrink();

    List<Widget> fields = [];

    if ([
      "fruits",
      "vegetables",
      "jam",
      "pomegranate",
      "apples",
      "honey",
    ].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _weightCategory == "byKg"
                    ? _averageWeightController
                    : _quantityController,
                label: _weightCategory == "byKg"
                    ? "Average Weight (KG)*"
                    : "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty
                    ? (_weightCategory == "byKg"
                          ? "Enter average weight"
                          : "Enter quantity")
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Weight Category*",
                value: _weightCategory,
                items: ["byKg", "byBox"],
                onChanged: (val) => setState(() => _weightCategory = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if ([
      "grain_seeds",
      "fertilizers",
      "animalsFeed",
      "cheese",
      "leafyGreen",
    ].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _averageWeightController,
                label: "Average Weight (KG)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter average weight" : null,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (["olive_oil", "pesticides"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _liquidQuantityController,
                label: "Quantity (Litre/Kg)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (["delivery"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: "Service Type*",
                value: _serviceType,
                items: ["sell", "rent"],
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (["agriculturalTools", "equipments"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _quantityController,
                label: "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Service Type*",
                value: _serviceType,
                items: ["sell", "rent"],
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (_category == "landServices") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _areaController,
                label: "Area (Sq M)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter area" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Service Type*",
                value: _serviceType,
                items: ["sell", "rent"],
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (_category == "workerServices") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _quantityController,
                label: "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField1(
                controller: _ageController,
                label: "Age*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter age" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Gender*",
                value: _gender,
                items: ["male", "female"],
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (_category == "irrigation") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _areaController,
                label: "Area (Sq M)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter area" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Service Type",
                value: _serviceType,
                items: ["sell", "install", "rent"],
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (_category == "live_stock") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: "Animal Type*",
                value: _liveStockCategory,
                items: ["cow", "goat", "chicken"],
                onChanged: (val) => setState(() => _liveStockCategory = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Gender",
                value: _gender,
                items: ["male", "female"],
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField1(
                controller: _ageController,
                label: "Age (Years)",
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _quantityController,
                label: "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    } else if (_category == "others") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField1(
                controller: _liquidQuantityController,
                label: "Quantity",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }

    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Container(
          height: 195,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14.5),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 14),
                  const SizedBox(width: 8),
                  Text(
                    "Category Specific Fields - ${_formatDisplayText(_category!)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...fields,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    final sampleImages = (widget.post.postImages is Map)
        ? (widget.post.postImages as Map).values
              .map((e) => e.toString())
              .toList()
        : (widget.post.postImages ?? []);

    final imagesToShow = sampleImages.isEmpty ? [] : sampleImages;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Images",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemCount: imagesToShow.length < 4 ? 4 : imagesToShow.length,
            itemBuilder: (context, index) {
              if (index >= imagesToShow.length) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imagesToShow[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _editPostForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -2,
                  ),
                  contentPadding: EdgeInsets.zero,
                  leading: Builder(
                    builder: (context) {
                      final imageUrl = _userImageController.text.trim();
                      final hasValidImage =
                          imageUrl.isNotEmpty &&
                          imageUrl != 'null' &&
                          imageUrl.startsWith('http');

                      final initialsWidget = Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _parseHexColor(
                            (widget.post.postUserImageColor.isNotEmpty == true)
                                ? widget.post.postUserImageColor
                                : '#cccccc',
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(
                              _userNameController.text.isNotEmpty
                                  ? _userNameController.text
                                  : 'User',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );

                      if (!hasValidImage) {
                        return initialsWidget;
                      }

                      return ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => initialsWidget,
                          errorWidget: (context, url, error) {
                            debugPrint('Error loading user image: $error');
                            return initialsWidget;
                          },
                        ),
                      );
                    },
                  ),
                  title: Row(
                    children: [
                      Text(
                        _userNameController.text.isNotEmpty
                            ? _userNameController.text
                            : 'Ali',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_userVerified == true ||
                          widget.post.postUserVerified == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 1),
                      GestureDetector(
                        onTap: () => _copyToClipboard(
                          _userMailController.text,
                          label: 'Email',
                        ),
                        child: Text(
                          _userMailController.text,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyToClipboard(
                          _userContactController.text,
                          label: 'Contact',
                        ),
                        child: Text(
                          _userContactController.text,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  trailing: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Location ----
                        Row(
                          children: [
                            SizedBox(
                              width: 70, // fixed label width
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _userLocationController.text,
                                  label: 'Location',
                                ),
                                child: Text(
                                  "Location",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _userLocationController.text,
                                  label: 'Location',
                                ),
                                child: Text(
                                  _userLocationController.text,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ---- User ID ----
                        Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _userIdController.text,
                                  label: 'User ID',
                                ),
                                child: Text(
                                  "User ID",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _userIdController.text,
                                  label: 'User ID',
                                ),
                                child: Text(
                                  _userIdController.text,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ---- Login Date ----
                        Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _postUserLoginController.text,
                                  label: 'Login Date',
                                ),
                                child: Text(
                                  "Login Date:",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _copyToClipboard(
                                  _postUserLoginController.text,
                                  label: 'Login Date',
                                ),
                                child: Text(
                                  _postUserLoginController.text,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _titleController,
                        label: "Post Title*",
                        validator: (v) => v!.isEmpty ? "Enter title" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: "City*",
                        validator: (v) => v!.isEmpty ? "Enter city" : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: "Price*",
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? "Enter price" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCurrencyDropdownField()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _villageController,
                        label: "Village*",
                        validator: (v) => v!.isEmpty ? "Enter village" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField3(
                        controller: _viewsController,
                        label: "Post View",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final views = int.tryParse(v);
                            if (views == null || views < 0) {
                              return "Enter a valid number";
                            }
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _locationController,
                        label: "Location",
                        suffixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 38,
                            child: DropdownButtonFormField<String>(
                              onChanged: null,
                              value: _category,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                              hint: const Text(
                                "Select Category",
                                style: TextStyle(fontSize: 12),
                              ),
                              dropdownColor: Colors.white,
                              items: _getCategoryDropdownItems(),
                              // onChanged: _isLoading ? null : _onCategoryChanged,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: Colors.black,
                              ),
                              validator: (v) =>
                                  v == null ? "Select a category" : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // NEW: Add row for new fields (postNoLikes, postLimits, postIsColoredTimes)
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField3(
                        controller: _postNoLikesController,
                        label: "Number of Likes",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final likes = int.tryParse(v);
                            if (likes == null || likes < 0) {
                              return "Enter a valid number";
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    // const SizedBox(width: 16),
                    // Expanded(
                    //   child: _buildTextField3(
                    //     controller: _postLimitsController,
                    //     label: "Post Limits",
                    //     keyboardType: TextInputType.number,
                    //     inputFormatters: [
                    //       FilteringTextInputFormatter.digitsOnly
                    //     ],
                    //     validator: (v) {
                    //       if (v != null && v.isNotEmpty) {
                    //         final limits = int.tryParse(v);
                    //         if (limits == null || limits < 0) {
                    //           return "Enter a valid number";
                    //         }
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    // ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField3(
                        controller: _postIsColoredTimesController,
                        label: "Post Colored Times",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final times = int.tryParse(v);
                            if (times == null || times < 0) {
                              return "Enter a valid number";
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField3(
                        controller: _postTopTimeController,
                        label: "Post Featured Time",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField2(
                        controller: _additionalDetailsController,
                        label: "Additional Details",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(child: _buildCategorySpecificFields()),
                  ],
                ),

                const SizedBox(height: 5),
                const Text(
                  "Post Settings",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSwitchField(
                        label: "Featured Post",
                        value: _isFeatured,
                        onChanged: (val) => setState(() => _isFeatured = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchField(
                        label: "Top Post",
                        value: _isTop,
                        onChanged: (val) => setState(() => _isTop = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchField(
                        label: "Home Post",
                        value: _isHomePost,
                        onChanged: (val) => setState(() => _isHomePost = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildSwitchField(
                        label: "Post Colored",
                        value: _isPostColored,
                        onChanged: (val) =>
                            setState(() => _isPostColored = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchField(
                        label: "User Verified",
                        value: _userVerified,
                        onChanged: (val) => setState(() => _userVerified = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchField(
                        label: "Approved",
                        value: _isApproved,
                        onChanged: (val) => setState(() => _isApproved = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSwitchField(
                        label: "Sold Post",
                        value: _isSold,
                        onChanged: (val) => setState(() => _isSold = val),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            "GO BACK",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.sourceScreen == 'dashboard') ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _cancelPostRequest,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 0),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              "CANCEL REQUEST",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "UPDATE POST",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(),
                  Container(
                    padding: const EdgeInsets.only(
                      right: 30,
                      left: 30,
                      bottom: 30,
                      top: 20,
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          size: 24,
                                          color: Colors.black,
                                          weight: 2,
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                        hoverColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                        disabledColor: Colors.black,
                                        style: ButtonStyle(
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Edit Post',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Post / Edit Post',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _editPostForm()),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: _buildImageGallery()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _villageController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _additionalDetailsController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _areaController.dispose();
    _averageWeightController.dispose();
    _liquidQuantityController.dispose();
    _userContactController.dispose();
    _userIdController.dispose();
    _userImageController.dispose();
    _userLocationController.dispose();
    _userMailController.dispose();
    _userNameController.dispose();
    _viewsController.dispose();

    // NEW: Dispose new controllers
    _postNoLikesController.dispose();
    _postLimitsController.dispose();
    _postIsColoredTimesController.dispose();
    _postTopTimeController.dispose();

    super.dispose();
  }
}
