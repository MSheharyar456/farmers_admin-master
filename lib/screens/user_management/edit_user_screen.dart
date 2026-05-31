import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../common/app_header.dart';
import '../../common/side_menu.dart';
import '../../repositories/user_repository.dart';
import '../../services/admin_server_auth_service.dart';
import '../../widgets/loading_overlay.dart';

class EditUserScreen extends StatefulWidget {
  final Map user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  static const int _dayMillis = 24 * 60 * 60 * 1000;
  final _formKey = GlobalKey<FormState>();
  final AdminServerAuthService _authService = AdminServerAuthService();
  late UserRepository _userRepository;
  String loginDate = ''; // ✅ Declare it here

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _userPostLimitController;
  late TextEditingController _userUpdatePostLimitController;
  late TextEditingController _userFollowingController;
  late TextEditingController _totalFollowersController;
  late TextEditingController _userTotalPostsTimeController;
  //late TextEditingController _addressController;
  late final int _initialUserTotalPostsTime;

  bool _userIsVerified = false;
  final String _month = "January";
  final String _day = "1";
  final String _year = "2000";
  bool _isLoading = false;
  bool _isImageLoading = false;

  String? _uploadedImagePath;
  Uint8List? _uploadedImageBytes;

  // Usage tracking
  int _postsUsed = 0;
  int _editsUsed = 0;
  bool _isLoadingUsage = false;

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    final user = widget.user;
    final userId = user['id'] as String? ?? user['uid'] as String?;
    _userRepository = UserRepository(_authService);

    _nameController = TextEditingController(text: user['userName'] ?? '');
    _phoneController = TextEditingController(text: user['userContact'] ?? '');
    _emailController = TextEditingController(text: user['userMail'] ?? '');
    _userPostLimitController = TextEditingController(
      text: (user['userPostLimit'] ?? 0).toString(),
    );
    _userUpdatePostLimitController = TextEditingController(
      text: (user['userUpdatePostLimit'] ?? 0).toString(),
    );
    _userFollowingController = TextEditingController(
      text: (user['userFollowing'] ?? 0).toString(),
    );
    _totalFollowersController = TextEditingController(
      text: (user['totalFollowersCount'] ?? 0).toString(),
    );
    _userTotalPostsTimeController = TextEditingController(
      text: (user['userTotalPostsTime'] ?? 0).toString(),
    );
    _initialUserTotalPostsTime =
        int.tryParse((user['userTotalPostsTime'] ?? 0).toString()) ?? 0;
    //_addressController = TextEditingController(text: user['userAddress'] ?? '');

    _userIsVerified = user['userIsVerified'] ?? false;

    // Debug the image URL
    print('[EDIT_USER][INIT] user keys: ${user.keys.toList()}');
    print('[EDIT_USER][INIT] raw user data: $user');
    print('[EDIT_USER][INIT] profileImage=${user['profileImage']}');
    print('[EDIT_USER][INIT] profile_image=${user['profile_image']}');
    print('[EDIT_USER][INIT] userImage=${user['userImage']}');
    print('[EDIT_USER][INIT] user_image=${user['user_image']}');
    print('[EDIT_USER][INIT] image=${user['image']}');
    print('[EDIT_USER][INIT] profileColor=${user['profileColor']}');
    print('[EDIT_USER][INIT] profile_color=${user['profile_color']}');
    print('[EDIT_USER][INIT] userImageColor=${user['userImageColor']}');
    print('[EDIT_USER][INIT] user_profile_color=${user['user_profile_color']}');
    print('[EDIT_USER][INIT] sellerColor=${user['sellerColor']}');
    print('[EDIT_USER][INIT] seller_color=${user['seller_color']}');

    // Get image URL from whichever backend field is present
    _uploadedImagePath = _firstNonEmptyString([
      user['profileImage'],
      user['profile_image'],
      user['userImage'],
      user['user_image'],
      user['image'],
    ]);
    print('[EDIT_USER][INIT] selected image path: $_uploadedImagePath');

    // If it's a Google image URL, try to cache it to Firebase Storage
    if (_uploadedImagePath != null &&
        _uploadedImagePath!.contains('googleusercontent.com')) {
      print('[EDIT_USER][INIT] detected googleusercontent image, caching...');
      _cacheGoogleImage(_uploadedImagePath!);
    }

    loginDate = _formatTimestamp(user['userLoginDate']);
    print('[EDIT_USER][INIT] loginDate formatted: $loginDate');

    // Fetch usage data
    _fetchUserUsage();
  }

  /// Fetch user's posts to calculate usage statistics
  Future<void> _fetchUserUsage() async {
    setState(() => _isLoadingUsage = true);
    try {
      final user = widget.user;
      final userId = user['id'] as String? ?? user['uid'] as String?;
      if (userId == null) return;

      // Get posts used from user data directly (passed from backend)
      final postLimitUsed = user['userPostLimitUsed'] ?? user['postLimitUsed'] ?? 0;

      // Fetch posts to calculate edit usage
      final posts = await _userRepository.getUserPosts(userId);

      // Calculate edits used (sum of postIsUpdate across all posts)
      int totalEdits = 0;
      for (final post in posts) {
        final updateCount = post['postIsUpdate'] ?? post['isUpdate'] ?? 0;
        totalEdits += updateCount is int ? updateCount : int.tryParse(updateCount.toString()) ?? 0;
      }

      setState(() {
        _postsUsed = postLimitUsed is int ? postLimitUsed : int.tryParse(postLimitUsed.toString()) ?? 0;
        _editsUsed = totalEdits;
      });

      print('[EDIT_USER] Usage fetched - postsUsed: $_postsUsed, editsUsed: $_editsUsed');
    } catch (e) {
      print('[EDIT_USER] Error fetching usage: $e');
    } finally {
      setState(() => _isLoadingUsage = false);
    }
  }

  // Method to cache Google profile image to Firebase Storage
  Future<void> _cacheGoogleImage(String googleImageUrl) async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      print('[EDIT_USER][CACHE] Attempting to cache Google image: $googleImageUrl');

      final userId =
          widget.user['id'] as String? ?? widget.user['uid'] as String?;
      if (userId == null || userId.isEmpty) {
        print('[EDIT_USER][CACHE] userId missing; abort cache');
        setState(() {
          _isImageLoading = false;
        });
        return;
      }
      print('[EDIT_USER][CACHE] userId=$userId');

      // First, check if we already have a cached version in Firebase Storage
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
          'user_profiles/$userId/profile.jpg',
        );

        print('[EDIT_USER][CACHE] checking existing storage object: user_profiles/$userId/profile.jpg');
        final cachedUrl = await storageRef.getDownloadURL();

        // If we got here, the image already exists in Firebase Storage
        print('[EDIT_USER][CACHE] Using cached image from Firebase Storage: $cachedUrl');

        setState(() {
          _uploadedImagePath = cachedUrl;
          _isImageLoading = false;
        });

        // Update database if it's still pointing to Google URL
        final currentImage = _firstNonEmptyString([
          widget.user['profileImage'],
          widget.user['profile_image'],
          widget.user['userImage'],
          widget.user['user_image'],
          widget.user['image'],
        ]);
        if (currentImage != cachedUrl) {
          print('[EDIT_USER][CACHE] backend image differs, updating profileImage to cached url');
          await _userRepository.updateUser(userId, {'profileImage': cachedUrl});
        } else {
          print('[EDIT_USER][CACHE] backend already matches cached url');
        }

        return;
      } catch (e) {
        // Image doesn't exist in storage yet, continue to download and upload
        print('[EDIT_USER][CACHE] No cached image found, downloading from Google... $e');
      }

      // Download the image from Google
      final response = await http.get(Uri.parse(googleImageUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        print('[EDIT_USER][CACHE] downloaded google image bytes: ${bytes.length}');

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child(
          'user_profiles/$userId/profile.jpg',
        );

        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Get the download URL
        final downloadUrl = await storageRef.getDownloadURL();
        print('[EDIT_USER][CACHE] new Firebase download URL: $downloadUrl');

        // Update backend database
        await _userRepository.updateUser(userId, {'profileImage': downloadUrl});
        print('[EDIT_USER][CACHE] backend updated with profileImage=$downloadUrl');

        // Update local state
        setState(() {
          _uploadedImagePath = downloadUrl;
          _isImageLoading = false;
        });

        print('Successfully cached image to Firebase Storage: $downloadUrl');
      } else {
        print('[EDIT_USER][CACHE] Failed to download Google image: ${response.statusCode}');
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      print('[EDIT_USER][CACHE] Error caching Google image: $e');
      setState(() {
        _isImageLoading = false;
      });
      // Keep using the original URL if caching fails
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _uploadedImageBytes = bytes;
          _uploadedImagePath = null;
        });
      } else {
        setState(() {
          _uploadedImagePath = pickedFile.path;
          _uploadedImageBytes = null;
        });
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null || timestamp == 0) return "N/A";

      int millis;
      if (timestamp is int) {
        millis = timestamp;
      } else if (timestamp is double) {
        millis = timestamp.toInt();
      } else if (timestamp is Map && timestamp.containsKey('_seconds')) {
        // sometimes Firebase stores in weird map structure
        millis = (timestamp['_seconds'] * 1000).toInt();
      } else if (timestamp is DateTime) {
        millis = timestamp.millisecondsSinceEpoch;
      } else if (timestamp is String) {
        final parsed = DateTime.tryParse(timestamp);
        if (parsed == null) return "N/A";
        millis = parsed.millisecondsSinceEpoch;
      } else if (timestamp is Map &&
          timestamp.containsKey('millisecondsSinceEpoch')) {
        final raw = timestamp['millisecondsSinceEpoch'];
        if (raw is int) {
          millis = raw;
        } else if (raw is double) {
          millis = raw.toInt();
        } else {
          return "N/A";
        }
      } else {
        return "N/A";
      }

      if (millis == 0) return "N/A";

      final date = DateTime.fromMillisecondsSinceEpoch(millis);
      return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "N/A";
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    print(_userIsVerified);
    try {
      final updatedData = {
        // "userName": _nameController.text.trim(),
        // "userContact": _phoneController.text.trim(),
        // "userMail": _emailController.text.trim(),
        //
        "userIsVerified": _userIsVerified,
        "userPostLimit":
            int.tryParse(_userPostLimitController.text.trim()) ?? 0,
        "userUpdatePostLimit":
            int.tryParse(_userUpdatePostLimitController.text.trim()) ?? 0,
        "userFollowing":
            int.tryParse(_userFollowingController.text.trim()) ?? 0,
        "userFollowerBoost":
            (int.tryParse(_totalFollowersController.text.trim()) ?? 0) - (widget.user['actualFollowersCount'] ?? 0),
        // "userProfileImage": _uploadedImagePath ?? "",
        // "updatedAt": DateTime.now().millisecondsSinceEpoch,
      };

      final currentTotalPostDays =
          int.tryParse(_userTotalPostsTimeController.text.trim()) ?? 0;
      if (currentTotalPostDays != _initialUserTotalPostsTime) {
        updatedData["userTotalPostsTime"] = currentTotalPostDays;
        updatedData["userTotalPostsExpiryTime"] = DateTime.now()
            .add(Duration(days: currentTotalPostDays))
            .millisecondsSinceEpoch;
      }

      final userId = widget.user['id'] as String? ?? widget.user['uid'] as String?;
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _userRepository.updateUser(userId, updatedData);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      String errorMessage = "Failed to update user. ";

      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection and try again.";
      } else if (e.toString().contains('permission')) {
        errorMessage += "You don't have permission to update this user.";
      } else {
        errorMessage += "Please try again later.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _updateUser,
          ),
        ),
      );

      debugPrint('Error updating user: $e');
    }
  }
  Widget _buildTextField1({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),

        SizedBox(
          height: 40,
          child: TextFormField(
             readOnly: true,
            style: TextStyle(fontSize: 12),
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: !_isLoading,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
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
  /// Build a text field for limits with usage info displayed
  Widget _buildLimitTextField({
    required String label,
    required TextEditingController controller,
    required int used,
    required int limit,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final remaining = limit - used;
    final color = remaining <= 0 ? Colors.red : (remaining <= 1 ? Colors.orange : Colors.green);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            if (_isLoadingUsage)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  'Used: $used, Remaining: $remaining',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextFormField(
            style: const TextStyle(fontSize: 12),
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            enabled: !_isLoading,
            inputFormatters: inputFormatters,
            onChanged: (_) {
              // Recalculate remaining when limit changes
              setState(() {});
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _parseIntValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  DateTime? _parseDateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      final millis = value.toInt();
      if (millis <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final parsedInt = int.tryParse(trimmed);
      if (parsedInt != null && parsedInt > 0) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt);
      }
      return DateTime.tryParse(trimmed);
    }
    if (value is Map && value.containsKey('millisecondsSinceEpoch')) {
      final raw = value['millisecondsSinceEpoch'];
      final millis = raw is int
          ? raw
          : raw is double
              ? raw.toInt()
              : int.tryParse(raw?.toString() ?? '');
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    return null;
  }

  String _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    print('[EDIT_USER][IMG] normalize input="$url" trimmed="$trimmed"');
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      print('[EDIT_USER][IMG] already absolute: $trimmed');
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      final resolved = 'https:$trimmed';
      print('[EDIT_USER][IMG] protocol-relative resolved: $resolved');
      return resolved;
    }
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final resolved = '$base$path';
    print('[EDIT_USER][IMG] relative resolved: $resolved');
    return resolved;
  }

  DateTime? _getUserTotalPostExpiry() {
    final user = widget.user;
    return _parseDateTimeValue(
      user['userTotalPostsExpiryTime'] ??
          user['post_limit_expires_at'] ??
          user['postLimitExpiresAt'] ??
          user['postLimitExpiresAtMs'],
    );
  }

  int _getTotalPostDays() {
    return _parseIntValue(_userTotalPostsTimeController.text, fallback: 0);
  }

  int _getRemainingPostDays() {
    final expiry = _getUserTotalPostExpiry();
    if (expiry == null) return 0;
    final remainingMs = expiry.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs + _dayMillis - 1) ~/ _dayMillis;
  }

  int _getUsedPostDays() {
    final totalDays = _getTotalPostDays();
    if (totalDays <= 0) return 0;
    final usedDays = totalDays - _getRemainingPostDays();
    if (usedDays < 0) return 0;
    if (usedDays > totalDays) return totalDays;
    return usedDays;
  }

  Widget _buildPostTimerSummary() {
    final totalDays = _getTotalPostDays();
    final usedDays = _getUsedPostDays();
    final remainingDays = _getRemainingPostDays();
    final summaryColor =
        remainingDays <= 0 && totalDays > 0 ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: summaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: summaryColor.withOpacity(0.25)),
      ),
      child: Text(
        'Used: $usedDays days   Remaining: $remainingDays days   Total: $totalDays days',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: summaryColor,
        ),
      ),
    );
  }

  Widget _buildTimerTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final totalDays = _getTotalPostDays();
    final usedDays = _getUsedPostDays();
    final remainingDays = _getRemainingPostDays();
    final summaryColor =
        remainingDays <= 0 && totalDays > 0 ? Colors.red : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            if (_isLoadingUsage)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: summaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: summaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Used: $usedDays, Remaining: $remainingDays',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: summaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: TextFormField(
            style: const TextStyle(fontSize: 12),
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            enabled: !_isLoading,
            inputFormatters: inputFormatters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
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
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),

        SizedBox(
          height: 40,
          child: TextFormField(
            // readOnly: true,
            style: TextStyle(fontSize: 12),
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: !_isLoading,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: _isLoading ? null : onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _isLoading ? null : () => onChanged(!value),
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(5),
              border: Border.all(width: 1, color: Colors.black54),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            subtitle,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: value ? Colors.green : Colors.grey[300],
                    ),
                    child: Stack(
                      children: [
                        // ON/OFF text
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
                        // White circle thumb
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: value ? 35 : 5,
                          top: 4,
                          child: Container(
                            width: 18,
                            height: 18,
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
        ),
      ],
    );
  }

  /// Parses hex color string to Color
  Color _parseHexColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '').trim();
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      } else if (h.length == 8) {
        return Color(int.parse(h, radix: 16));
      }
    } catch (e) {
      print('Error parsing color: $e');
    }
    return fallback;
  }

  /// Get initials from user name
  String get _userInitials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildImagePreview() {
    // Show loading indicator while caching/loading image
    if (_isImageLoading) {
      print('[EDIT_USER][IMG] build preview -> image loading state');
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    // Get user's profile color from the user data
    final user = widget.user;
    final colorHex = ([
      user['profileColor'],
      user['profile_color'],
      user['userImageColor'],
      user['user_profile_color'],
      user['sellerColor'],
      user['seller_color'],
      user['profileImageColor'],
      user['profile_image_color'],
      user['imageColor'],
      user['image_color'],
    ].firstWhere(
      (value) => value != null && value.toString().trim().isNotEmpty,
      orElse: () => null,
    ))?.toString();
    final bgColor = _parseHexColor(colorHex, fallback: Colors.grey.shade300);
    print('[EDIT_USER][IMG] colorHex="$colorHex" bgColor=$bgColor');

    // Check if image URL exists and is not the default placeholder.
    final hasValidImage = _uploadedImagePath != null &&
        _uploadedImagePath!.isNotEmpty &&
        _uploadedImagePath != 'default_pfp.jpg' &&
        !_uploadedImagePath!.endsWith('default_pfp.jpg');
    print('[EDIT_USER][IMG] _uploadedImagePath=$_uploadedImagePath hasValidImage=$hasValidImage');

    if (hasValidImage) {
      print('[EDIT_USER][IMG] rendering image preview');
      final resolvedImageUrl = _normalizeImageUrl(_uploadedImagePath!);
      print('[EDIT_USER][IMG] resolved image url=$resolvedImageUrl');
      return Container(
        height: 210,
        width: 260,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            resolvedImageUrl,
            width: 260,
            height: 210,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              print(
                '[EDIT_USER][IMG] network loading progress expected=${loadingProgress.expectedTotalBytes} loaded=${loadingProgress.cumulativeBytesLoaded}',
              );
              return Container(
                color: bgColor,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('[EDIT_USER][IMG] Error loading image: $error');
              // Fallback to initials on error
              print('[EDIT_USER][IMG] falling back to initials after image error');
              return Center(
                child: Text(
                  _userInitials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // No valid image - show colored rectangle with initials
    print('[EDIT_USER][IMG] no valid image, showing initials only');
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _userInitials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
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
          SideMenu(),

          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(),
                    Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.black,
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                Navigator.pop(context);
                                              },
                                      ),
                                      Text(
                                        'Edit Customer',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Dashboard / Customer's List / Edit Customer",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.normal,
                                          fontFamily: 'Roboto',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                label: "Enter Name*",
                                                controller: _nameController,
                                                validator: (v) => v!.isEmpty
                                                    ? "Enter name"
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildTextField(
                                                label: "Email*",
                                                controller: _emailController,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) {
                                                    return "Enter email";
                                                  }
                                                  if (!v.contains('@')) {
                                                    return "Enter valid email";
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                label: "Phone Number",
                                                controller: _phoneController,
                                                keyboardType:
                                                    TextInputType.phone,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\+?[0-9]*$'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Login Date",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),

                                                  Container(
                                                    height: 40,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                      color:
                                                          Colors.grey.shade100,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          loginDate,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          color: Colors.grey,
                                                          size: 14,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildLimitTextField(
                                                label: "User Post Limit",
                                                controller:
                                                    _userPostLimitController,
                                                used: _postsUsed,
                                                limit: int.tryParse(_userPostLimitController.text) ?? 0,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly
                                                ],
                                                validator: (v) {
                                                  if (v != null &&
                                                      v.isNotEmpty) {
                                                    if (int.tryParse(v) ==
                                                        null) {
                                                      return "Enter valid number";
                                                    }
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildLimitTextField(
                                                label: "User Update Post Limit",
                                                controller:
                                                    _userUpdatePostLimitController,
                                                used: _editsUsed,
                                                limit: int.tryParse(_userUpdatePostLimitController.text) ?? 0,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly
                                                ],
                                                validator: (v) {
                                                  if (v != null &&
                                                      v.isNotEmpty) {
                                                    if (int.tryParse(v) ==
                                                        null) {
                                                      return "Enter valid number";
                                                    }
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            // Expanded(
                                            //   child: _buildTextField(
                                            //     label: "User Following (Min Required)",
                                            //     controller:
                                            //         _userFollowingController,
                                            //     keyboardType:
                                            //         TextInputType.number,
                                            //     inputFormatters: [
                                            //       FilteringTextInputFormatter.digitsOnly
                                            //     ],
                                            //     validator: (v) {
                                            //       if (v != null &&
                                            //           v.isNotEmpty) {
                                            //         if (int.tryParse(v) ==
                                            //             null) {
                                            //           return "Enter valid number";
                                            //         }
                                            //       }
                                            //       return null;
                                            //     },
                                            //   ),
                                            // ),

                                            Expanded(
                                              child: _buildTextField(
                                                label: "Total Followers",
                                                controller:
                                                    _totalFollowersController,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly
                                                ],
                                                validator: (v) {
                                                  if (v != null &&
                                                      v.isNotEmpty) {
                                                    if (int.tryParse(v) ==
                                                        null) {
                                                      return "Enter valid number";
                                                    }
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildTimerTextField(
                                                label: "User Total Post Timer",
                                                controller:
                                                _userTotalPostsTimeController,
                                                keyboardType:
                                                TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly
                                                ],
                                                validator: (v) {
                                                  if (v != null &&
                                                      v.isNotEmpty) {
                                                    if (int.tryParse(v) ==
                                                        null) {
                                                      return "Enter valid number";
                                                    }
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: _buildSwitchField(
                                                label: "User Verified",
                                                subtitle:
                                                "Enable verification status for this customer",
                                                value: _userIsVerified,
                                                onChanged: (val) {
                                                  print(
                                                    "before update: $_userIsVerified",
                                                  );
                                                  setState(() {
                                                    _userIsVerified = val;
                                                    print(
                                                      "After update: $_userIsVerified",
                                                    );
                                                  });
                                                },
                                              ),
                                            )
                                          ],
                                        ),

                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 40,
                                                child: OutlinedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : () => Navigator.pop(
                                                          context,
                                                        ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 0,
                                                        ),
                                                    side: BorderSide(
                                                      color: Colors.grey[400]!,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "CANCEL",
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SizedBox(
                                                height: 40,
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _updateUser,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 0,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                    ),
                                                  ),
                                                  child: _isLoading
                                                      ? const SizedBox(
                                                          height: 15,
                                                          width: 15,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Text(
                                                          "SAVE CHANGES",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: _buildImagePreview(),
                                        ),
                                        const SizedBox(height: 12),
                                        // OutlinedButton.icon(
                                        //   onPressed: _isLoading ? null : _pickImage,
                                        //   icon: SvgPicture.asset(
                                        //     "images/ic_farm_upload_photo.svg",
                                        //     width: 20,
                                        //     height: 20,
                                        //     colorFilter: ColorFilter.mode(
                                        //       _isLoading
                                        //           ? Colors.grey
                                        //           : Colors.black,
                                        //       BlendMode.srcIn,
                                        //     ),
                                        //   ),
                                        //   label: const Text("CHANGE PHOTO"),
                                        //   style: OutlinedButton.styleFrom(
                                        //     padding: const EdgeInsets.symmetric(
                                        //         horizontal: 16, vertical: 12),
                                        //     side: const BorderSide(
                                        //         color: Colors.black54),
                                        //   ),
                                        // )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_isLoading)
                                const Positioned.fill(
                                  child: LoadingOverlay(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _userPostLimitController.dispose();
    _userUpdatePostLimitController.dispose();
    _userFollowingController.dispose();
    _totalFollowersController.dispose();
    _userTotalPostsTimeController.dispose();
    //_addressController.dispose();
    super.dispose();
  }
}
