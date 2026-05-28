import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../common/app_header.dart';
import '../../common/side_menu.dart';
import '../../repositories/user_repository.dart';
import '../../services/admin_server_auth_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
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
    //_addressController = TextEditingController(text: user['userAddress'] ?? '');

    _userIsVerified = user['userIsVerified'] ?? false;

    // Debug the image URL
    print('User data from Firebase:');
    print(user);

    // Get image URL
    _uploadedImagePath = user['userImage'] ?? '';

    // If it's a Google image URL, try to cache it to Firebase Storage
    if (_uploadedImagePath != null &&
        _uploadedImagePath!.contains('googleusercontent.com')) {
      _cacheGoogleImage(_uploadedImagePath!);
    }

    loginDate = _formatTimestamp(user['userLoginDate']);

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

      print('Attempting to cache Google image...');

      final userId =
          widget.user['id'] as String? ?? widget.user['uid'] as String?;
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isImageLoading = false;
        });
        return;
      }

      // First, check if we already have a cached version in Firebase Storage
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
          'user_profiles/$userId/profile.jpg',
        );

        final cachedUrl = await storageRef.getDownloadURL();

        // If we got here, the image already exists in Firebase Storage
        print('Using cached image from Firebase Storage: $cachedUrl');

        setState(() {
          _uploadedImagePath = cachedUrl;
          _isImageLoading = false;
        });

        // Update database if it's still pointing to Google URL
        if (widget.user['userImage'] != cachedUrl) {
          await _userRepository.updateUser(userId, {'profileImage': cachedUrl});
        }

        return;
      } catch (e) {
        // Image doesn't exist in storage yet, continue to download and upload
        print('No cached image found, downloading from Google...');
      }

      // Download the image from Google
      final response = await http.get(Uri.parse(googleImageUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

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

        // Update backend database
        await _userRepository.updateUser(userId, {'profileImage': downloadUrl});

        // Update local state
        setState(() {
          _uploadedImagePath = downloadUrl;
          _isImageLoading = false;
        });

        print('Successfully cached image to Firebase Storage: $downloadUrl');
      } else {
        print('Failed to download Google image: ${response.statusCode}');
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      print('Error caching Google image: $e');
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
        "userTotalPostsTime":
            int.tryParse(_userTotalPostsTimeController.text.trim()) ?? 0,
        "userTotalPostsExpiryTime": DateTime.now()
            .add(Duration(days: int.tryParse(_userTotalPostsTimeController.text.trim()) ?? 0))
            .millisecondsSinceEpoch,
        // "userProfileImage": _uploadedImagePath ?? "",
        // "updatedAt": DateTime.now().millisecondsSinceEpoch,
      };

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
    final colorHex = user['profileColor'] as String? ?? user['profile_color'] as String?;
    final bgColor = _parseHexColor(colorHex, fallback: const Color(0xFFDAD721));

    // Check if image URL exists, is not empty, and is not default_pfp.jpg
    final hasValidImage = _uploadedImagePath != null &&
        _uploadedImagePath!.isNotEmpty &&
        _uploadedImagePath != 'default_pfp.jpg' &&
        !_uploadedImagePath!.endsWith('default_pfp.jpg') &&
        !_uploadedImagePath!.contains('googleusercontent.com');

    if (hasValidImage) {
      print('Loading user profile image: $_uploadedImagePath');
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
            _uploadedImagePath!,
            width: 260,
            height: 210,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
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
              print('Error loading image: $error');
              // Fallback to initials on error
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
                                              child: _buildTextField(
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
                                      borderRadius: BorderRadius.circular(12),
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
