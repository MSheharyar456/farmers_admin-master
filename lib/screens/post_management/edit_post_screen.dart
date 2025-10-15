import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart' hide SideMenu;
import 'package:farmers_admin/screens/post_management/post_management_screen.dart';
import 'package:farmers_admin/screens/user_management/user_screen.dart';
import 'package:farmers_admin/widgets/cancel_request.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('productsPostData');

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

  late String? _category;
  late String _gender;
  late String _weightCategory;
  late String _liveStockCategory;
  late String _serviceType;
  late String _quantityUnit;

// Add this field in _EditPostScreenState:
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
    "Fruit",
    "Vegetables",
    "Jam",
    "Pomegranate",
    "Apples",
    "Honey",
    "Grain&Seeds",
    "Fertilizers",
    "Animals Feed",
    "Cheese",
    "Leafy Greens",
    "Olive&Oils",
    "Pesticides",
    "Agriculture Tools",
    "Delivery Services",
    "Equipments",
    "Land Services",
    "Worker Services",
    "Irrigation System",
    "Live Stock",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    final post = widget.post;

    // Initialize common controllers
    _titleController = TextEditingController(text: post.postTitle);
    _cityController = TextEditingController(text: post.postCity);
    _villageController = TextEditingController(text: post.postVillage);
    _priceController = TextEditingController(text: post.postPrice?.toString() ?? '');
    _locationController = TextEditingController(text: post.postLocation ?? '');
    _additionalDetailsController = TextEditingController(text: post.postAdditionalDetails ?? '');

    // Initialize category-specific controllers
    _quantityController = TextEditingController(text: post.postQuantity?.toString() ?? '');
    _weightController = TextEditingController(text: post.postWeight?.toString() ?? '');
    _ageController = TextEditingController(text: post.postAge?.toString() ?? '');
    _areaController = TextEditingController(text: post.postArea?.toString() ?? '');
    _averageWeightController = TextEditingController(text: post.postAverageWeight?.toString() ?? '');
    _liquidQuantityController = TextEditingController(text: post.postLiquidQuantity?.toString() ?? '');

    // Initialize category
    _category = _categories.contains(post.postCategory) ? post.postCategory : null;

    // Initialize category-specific dropdowns with safe defaults
    _gender = post.postGender ?? "Male";
    _weightCategory = post.postWeightCategory ?? "byKg";
    _liveStockCategory = post.postLiveStockCategory ?? "Cow";
    _serviceType = post.postServiceType ?? "sell";
    _quantityUnit = post.postWeightCategory ?? "Litre";
    _isCancelled = post.postIsCancelled ?? false;  // Add this line
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
  }


  // Option 1: Update the _onCategoryChanged method to set appropriate defaults
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
      _gender = "Male";
      _weightCategory = "byKg";
      _liveStockCategory = "Cow";
      _quantityUnit = "Litre";

      // ✅ Set appropriate service type based on category
      if (newCategory == "Worker Services") {
        _serviceType = "daily";  // Default for Worker Services
      } else if (newCategory == "Irrigation System") {
        _serviceType = "sell";  // Default for Irrigation System (has sell, install, rent)
      } else {
        _serviceType = "sell";  // Default for other categories
      }
    });
  }


  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              ClipRRect( child: SvgPicture.asset( "images/delete.svg", semanticsLabel: "Your crop icon", width: 60, height: 60, ), ),

              const SizedBox(width: 12),
              const Text(
                'Cancel Changes?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel? All unsaved changes will be lost.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Continue Editing',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add this method for cancel request:
  Future<void> _cancelPostRequest() async {
    await showCancelRequestDialog(
      context: context,
      title: 'Cancel Post Request?',
      message: 'Are you sure you want to cancel this post request? This action will mark the post as cancelled.',
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          await _dbRef.child(widget.post.postId).update({
            'postIsCancelled': true,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }).timeout(
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

          // Navigate back after a short delay
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Base post data
      Map<String, dynamic> postData = {
        "postIsCancelled": _isCancelled,  // Add this line
        "postTitle": _titleController.text.trim(),
        "postCity": _cityController.text.trim(),
        "postVillage": _villageController.text.trim(),
        "postPrice": int.tryParse(_priceController.text.trim()) ?? 0,
        "postUserLocation": _locationController.text.trim(),
        "postAdditionalDetails": _additionalDetailsController.text.trim(),
        "postCategory": _category ?? "Others",
        "postIsApproved": _isApproved,
        "postIsFeatured": _isFeatured,
        "postIsHomePost": _isHomePost,
        "postIsLiked": _isLiked,
        "postIsColored": _isPostColored,
        "postIsSold": _isSold,
        "postIsTop": _isTop,
        "postIsUpdate": true,
        "postUserVerified": _userVerified,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      };

      // Add category-specific fields based on organized groups
      switch (_category) {
      // Group 1: Fruit, Vegetables, Jam, Pomegranate, Apples, Honey
        case "Fruit":
        case "Vegetables":
        case "Jam":
        case "Pomegranate":
        case "Apples":
        case "Honey":
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _weightCategory;
          break;

      // Group 2: Grains&Seeds, Fertilizers, Animals Feed, Cheese, Leafy Greens
        case "Grain&Seeds":
        case "Fertilizers":
        case "Animals Feed":
        case "Cheese":
        case "Leafy Greens":
          if (_averageWeightController.text.isNotEmpty) {
            postData["postAverageWeight"] = int.tryParse(_averageWeightController.text) ?? 0;
          }
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          break;

      // Group 3: Olive&Oils, Pesticides
        case "Olive&Oils":
        case "Pesticides":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] = int.tryParse(_liquidQuantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _quantityUnit;
          break;


      // Group 4: Agriculture Tools, Equipments
        case "Agriculture Tools":
        case "Delivery Services":
        if (_quantityController.text.isNotEmpty) {
          postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
        }
        postData["postServiceType"] = _serviceType;
        break;

        case "Equipments":
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          postData["postServiceType"] = _serviceType;
          break;

      // Group 5: Land Services
        case "Land Services":
          postData["postServiceType"] = _serviceType;
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = _areaController.text.trim();
          }
          break;

      // Group 6: Worker Services
        case "Worker Services":
          postData["postGender"] = _gender;
          postData["postServiceType"] = _serviceType;
          break;

      // Group 6: Worker Services
      //   case "Deliver Services":
      //     postData["rent"] = _;
      //     postData["sell"] = _serviceType;
      //     break;

      // Group 7: Irrigation System
        case "Irrigation System":
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = _areaController.text.trim();
          }
          postData["postServiceType"] = _serviceType;
          break;

      // Group 8: Live Stock
        case "Live Stock":
          postData["postLiveStockCategory"] = _liveStockCategory;
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          postData["postGender"] = _gender;
          if (_ageController.text.isNotEmpty) {
            postData["postAge"] = int.tryParse(_ageController.text) ?? 0;
          }
          break;

      // Group 9: Others
        case "Others":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] = int.tryParse(_liquidQuantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _quantityUnit;
          break;
      }

      await _dbRef.child(widget.post.postId).update(postData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Post updated successfully!"),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update post: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      debugPrint('Error updating post: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: _isLoading ? null : onChanged,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ))
              .toList(),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

  // Category-specific form fields
  Widget _buildCategorySpecificFields() {
    if (_category == null) return const SizedBox.shrink();

    List<Widget> fields = [];

    // Group 1: Fruit, Vegetables, Jam, Pomegranate, Apples, Honey
    if (["Fruit", "Vegetables", "Jam", "Pomegranate", "Apples", "Honey"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _quantityController,
                label: "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
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
    }
    // Group 2: Grains&Seeds, Fertilizers, Animals Feed, Cheese, Leafy Greens
    else if (["Grain&Seeds", "Fertilizers", "Animals Feed", "Cheese", "Leafy Greens"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _averageWeightController,
                label: "Average Weight (KG)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter average weight" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _quantityController,
                label: "Quantity",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }
    // Group 3: Olive&Oils, Pesticides
    else if (["Olive&Oils", "Pesticides"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _liquidQuantityController,
                label: "Quantity*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter quantity" : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Unit*",
                value: _quantityUnit,
                items: ["Litre", "Kg"],
                onChanged: (val) => setState(() => _quantityUnit = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }
    // Group 4: Agriculture Tools, Equipments
    else if (["Delivery Services"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
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
    }

    // Group 4: Agriculture Tools, Equipments
    else if (["Agriculture Tools", "Equipments"].contains(_category)) {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
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
    }
    // Group 5: Land Services
    else if (_category == "Land Services") {
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
            Expanded(
              child: _buildTextField(
                controller: _areaController,
                label: "Area (Square Meter)*",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter area" : null,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }
    // Group 6: Worker Services
    else if (_category == "Worker Services") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: "Gender*",
                value: _gender,
                items: ["Male", "Female"],
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Service Type",
                value: _serviceType,
                items: ["daily", "monthly", "seasonal"],
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }
    // Group 7: Irrigation System
    else if (_category == "Irrigation System") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _areaController,
                label: "Area (Square Meter)*",
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
    }
    // Group 8: Live Stock
    else if (_category == "Live Stock") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: "Animal Type*",
                value: _liveStockCategory,
                items: ["Cow", "Goat", "Chicken", "Sheep", "Camel"],
                onChanged: (val) => setState(() => _liveStockCategory = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Gender",
                value: _gender,
                items: ["Male", "Female"],
                onChanged: (val) => setState(() => _gender = val!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
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
              child: _buildTextField(
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
    }
    // Group 9: Others
    else if (_category == "Others") {
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _liquidQuantityController,
                label: "Quantity",
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Unit",
                value: _quantityUnit,
                items: ["Litre", "Kg", "Box"],
                onChanged: (val) => setState(() => _quantityUnit = val!),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ]);
    }

    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Category Specific Fields - $_category",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...fields,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    final sampleImages = (widget.post.postImages is Map)
        ? (widget.post.postImages as Map).values.map((e) => e.toString()).toList()
        : (widget.post.postImages ?? []);

    final imagesToShow = sampleImages.isEmpty
        ? List.generate(4, (index) => 'https://picsum.photos/200?random=$index')
        : sampleImages;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Images",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: imagesToShow.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imagesToShow[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
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

      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white,),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                const Text(
                  "Basic Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                        controller: _villageController,
                        label: "Village*",
                        validator: (v) => v!.isEmpty ? "Enter village" : null,
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _additionalDetailsController,
                        label: "Additional Details",
                      ),
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                      child: _buildTextField(
                        controller: _locationController,
                        label: "Location",
                        suffixIcon: const Icon(Icons.location_on,
                            color: Colors.grey),
                      ),
                    ),
                    SizedBox(width: 16,),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Category",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8,),
                          DropdownButtonFormField<String>(
                            value: _category,

                            decoration: InputDecoration(

                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            hint: Text("Select Category"),
                            dropdownColor: Colors.white,
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                                .toList(),
                            onChanged: _isLoading ? null : _onCategoryChanged,
                            validator: (v) =>
                            v == null ? "Select a category" : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Category Specific Fields
                _buildCategorySpecificFields(),

                // Post Settings Section
                const SizedBox(height: 16),
                const Text(
                  "Post Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
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
                        onChanged: (val) =>
                            setState(() => _userVerified = val),
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
                  ],
                ),

                // Action Buttons
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "GO BACK",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _cancelPostRequest,  // This calls the cancel dialog
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: const Text(
                          "CANCEL REQUEST",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(

                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
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
                            fontSize: 16,
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
          SideMenu(
            selectedIndex: 1,
            onItemTapped: (index) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(initialIndex: 0),
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                        Navigator.pop(context);
                                      },
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
                                const SizedBox(height: 8),
                                Text(
                                  'Post / Edit Post',
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
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Expanded(flex: 3, child: _editPostForm()),
                            SizedBox(width: 10,),
                            // Images Section
                            Expanded( flex: 2,child: _buildImageGallery()),

                          ],
                        ),
                      ],
                    ),
                  )
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
    super.dispose();
  }
}