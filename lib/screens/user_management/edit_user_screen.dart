import 'dart:typed_data';
import 'dart:io' show File;
import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../common/app_header.dart';
import '../../common/side_menu.dart';

class EditUserScreen extends StatefulWidget {
  final Map user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseReference _dbRef;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool _userIsVerified = false;
  String _month = "January";
  String _day = "1";
  String _year = "2000";
  bool _isLoading = false;

  String? _uploadedImagePath;
  Uint8List? _uploadedImageBytes;

  @override
  void initState() {
    super.initState();

    final user = widget.user;
    final userId = user['userId'] as String?;
    _dbRef = FirebaseDatabase.instance.ref().child('UsersAuthData/$userId');

    _nameController = TextEditingController(text: user['userName'] ?? '');
    _phoneController = TextEditingController(text: user['userContact'] ?? '');
    _emailController = TextEditingController(text: user['userMail'] ?? '');
    _addressController = TextEditingController(text: user['userAddress'] ?? '');

    final dob = user['userDOB'] as Map?;
    if (dob != null) {
      _month = dob['month'] ?? _month;
      _day = dob['day'] ?? _day;
      _year = dob['year'] ?? _year;
    }

    _userIsVerified = user['userIsVerified'] ?? false;
    _uploadedImagePath = user['userProfileImage'];
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

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        "userName": _nameController.text.trim(),
        "userContact": _phoneController.text.trim(),
        "userMail": _emailController.text.trim(),
        "userAddress": _addressController.text.trim(),
        "userDOB": {
          "month": _month,
          "day": _day,
          "year": _year,
        },
        "userIsVerified": _userIsVerified,
        "userProfileImage": _uploadedImagePath ?? "",
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      };

      await _dbRef.update(updatedData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

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

  Widget _buildTextField({
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
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: !_isLoading,
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
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: suffixIcon,
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
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
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
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: Colors.black54),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : () => onChanged(!value),
            child: AnimatedContainer(
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
                    left: value ? 8 : null,
                    right: value ? null : 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        value ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
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
                    left: value ? 32 : 4,
                    top: 4,
                    child: Container(
                      width: 24,
                      height: 24,
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
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Priority: 1. Newly picked bytes (web), 2. Newly picked file path (mobile), 3. Existing URL
    if (kIsWeb && _uploadedImageBytes != null) {
      return Image.memory(
        _uploadedImageBytes!,
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
      );
    } else if (!kIsWeb && _uploadedImagePath != null && !_uploadedImagePath!.startsWith('http')) {
      return Image.file(
        File(_uploadedImagePath!),
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
      );
    } else if (_uploadedImagePath != null && _uploadedImagePath!.startsWith('http')) {
      // Load existing network image
      return Image.network(
        _uploadedImagePath!,
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            color: Colors.grey[300],
            child: Center(
              child: Image.asset(
                "images/profile.jpg",
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }

    // Placeholder when no image
    return Container(
      height: 200,
      width: 200,
      color: Colors.grey[300],
      child: Center(
        child: Image.asset(
          "images/profile.jpg",
          width: 200,
          height: 200,
          fit: BoxFit.cover,
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
          SideMenu(
            selectedIndex: 2, // Current screen index
            onItemTapped: (index) {
              // Navigate back to dashboard with selected index
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(initialIndex: 0),
                ),
              );

            },
          ),

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
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.black),
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      Text(
                                        "Edit Customer",
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
                                  const SizedBox(height: 8),
                                  Text(
                                    "Dashboard / Customer's List / Edit Customer",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                      color: Colors.grey,
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
                                                validator: (v) =>
                                                v!.isEmpty ? "Enter name" : null,
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
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildTextField(
                                                label: "Phone Number",
                                                controller: _phoneController,
                                                keyboardType: TextInputType.phone,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _buildTextField(
                                                label: "Address",
                                                controller: _addressController,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey.shade100,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "$_month, ${_day.padLeft(2, '0')}, $_year",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 20),
                                        _buildSwitchField(
                                          label: "User Verified",
                                          subtitle:
                                          "Enable verification status for this customer",
                                          value: _userIsVerified,
                                          onChanged: (val) {
                                            setState(() {
                                              _userIsVerified = val;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () => Navigator.pop(context),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                                  side: BorderSide(
                                                      color: Colors.grey[400]!),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "CANCEL",
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed:
                                                _isLoading ? null : _updateUser,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                  CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                                    : const Text(
                                                  "SAVE CHANGES",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                    FontWeight.w600,
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
                              )
                            ],
                          ),
                        ],
                      ),
                    )
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
    _addressController.dispose();
    super.dispose();
  }
}