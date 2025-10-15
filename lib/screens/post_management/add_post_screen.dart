import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart' hide SideMenu;
import 'package:farmers_admin/screens/post_management/post_management_screen.dart';
import 'package:farmers_admin/screens/user_management/user_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('productsPostData');

  // Common Controllers
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _villageController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Category Specific Controllers
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _areaController = TextEditingController();
  final _averageWeightController = TextEditingController();
  final _liquidQuantityController = TextEditingController();

  String? _category;
  String _gender = "Male";
  String _weightCategory = "byKg";
  String _liveStockCategory = "Cow";
  String _serviceType = "sell";
  String _quantityUnit = "Litre";

  int _selectedIndex = 0;
  bool _isLoading = false;

  // Boolean fields
  bool _isApproved = true;
  bool _isFeatured = false;
  bool _isHomePost = true;
  bool _isLiked = false;
  bool _isPostColorAble = true;
  bool _isSold = false;
  bool _isTop = false;
  bool _isUpdate = false;
  bool _userVerified = false;

  // Organized category list as per requirements
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


  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPostRef = _dbRef.push();
      final postId = newPostRef.key;

      // Base post data
      Map<String, dynamic> postData = {
        "postItemID": postId,
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
        "postIsColored": _isPostColorAble,
        "postIsSold": _isSold,
        "postIsTop": _isTop,
        "postIsUpdate": _isUpdate,
        "postUserVerified": _userVerified,
        "postDate": DateTime.now().millisecondsSinceEpoch,
        "postNoLikes": 0,
        "postViews": 0,
        "postBarCode": "#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      };

      // Add category-specific fields based on your requirements
      switch (_category) {
      // Group 1: Fruit, Vegetables, Jam, Pomegranate, Apples, Honey - Weight in KG or Box
        case "Fruit":
        case "Vegetables":
        case "Jam":
        case "Pomegranate":
        case "Apples":
        case "Honey":
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _weightCategory; // byKg or byBox
          break;

      // Group 2: Grains&Seeds, Fertilizers, Animals Feed, Cheese, Leafy Greens - Average Weight
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

      // Group 3: Olive&Oils, Pesticides - Quantity in Litre or KG
        case "Olive&Oils":
        case "Pesticides":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] = int.tryParse(_liquidQuantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _quantityUnit; // Litre or Kg
          break;

      // Group 4: Agriculture Tools, Equipments - Quantity, Rent or Sell
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
          postData["postServiceType"] = _serviceType; // rent or sell
          break;

      // Group 5: Land Services - Rent or Sell, Area in Square Meter
        case "Land Services":
          postData["postServiceType"] = _serviceType; // rent or sell
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = _areaController.text.trim();
          }
          break;

      // Group 6: Worker Services - Gender (Male/Female)
        case "Worker Services":
          postData["postGender"] = _gender; // Male or Female
          postData["postServiceType"] = _serviceType;
          break;

      // Group 7: Irrigation System - Area in Square Meter
        case "Irrigation System":
          if (_areaController.text.isNotEmpty) {
            postData["postArea"] = _areaController.text.trim();
          }
          postData["postServiceType"] = _serviceType;
          break;

      // Group 8: Live Stock - Cow, Goat, Chicken and Quantity
        case "Live Stock":
          postData["postLiveStockCategory"] = _liveStockCategory; // Cow, Goat, Chicken
          if (_quantityController.text.isNotEmpty) {
            postData["postQuantity"] = int.tryParse(_quantityController.text) ?? 0;
          }
          postData["postGender"] = _gender;
          if (_ageController.text.isNotEmpty) {
            postData["postAge"] = int.tryParse(_ageController.text) ?? 0;
          }
          break;

      // Group 9: Others - Quantity in Litre, KG or Box
        case "Others":
          if (_liquidQuantityController.text.isNotEmpty) {
            postData["postLiquidQuantity"] = int.tryParse(_liquidQuantityController.text) ?? 0;
          }
          postData["postWeightCategory"] = _quantityUnit; // Litre, Kg, or Box
          break;
      }

      await newPostRef.set(postData).timeout(
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
          content: Text("Post added successfully!"),
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
          content: Text("Failed to add post: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      debugPrint('Error adding post: $e');
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

  // Category-specific form fields based on your requirements
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
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.black),
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Text(
                                      'Add Post',
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
                                  'Post / Add New Post',
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
                            Expanded(flex: 3, child: addPostForm()),
                            SizedBox(width: 10,),
                            Expanded(
                              flex: 2,
                              child: Container(
                                color: Colors.grey[50],
                                padding: const EdgeInsets.all(24),
                                child: _buildImageGallery(),
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
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    // Always show 4 sample placeholder images
    final imagesToShow =
    List.generate(4, (index) => 'https://picsum.photos/200?random=$index');

    return Column(
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green,),
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
    );
  }
  Widget addPostForm() {
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
                        validator: (v) =>
                        v!.isEmpty ? "Enter title" : null,
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
                        validator: (v) =>
                        v!.isEmpty ? "Enter village" : null,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _additionalDetailsController,
                        label: "Additional Details",
                      ),
                    ),
                    const SizedBox(width: 16),

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
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _category,
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Category*",
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
                const SizedBox(height: 32),
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
                        label: "Feature Post",
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
                        value: _isPostColorAble,
                        onChanged: (val) =>
                            setState(() => _isPostColorAble = val),
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
                    // const SizedBox(width: 16),
                    // Expanded(
                    //   child: _buildSwitchField(
                    //     label: "Sold",
                    //     value: _isSold,
                    //     onChanged: (val) => setState(() => _isSold = val),
                    //   ),
                    // ),
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
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePost,
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
                          "SAVE POST",
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
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _villageController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _ageController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _additionalDetailsController.dispose();
    _areaController.dispose();
    _averageWeightController.dispose();
    _liquidQuantityController.dispose();
    super.dispose();
  }
}




