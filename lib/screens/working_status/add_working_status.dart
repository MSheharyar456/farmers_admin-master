import 'package:farmers_admin/services/admin_working_status_api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../common/app_header.dart';
import '../../common/side_menu.dart';

class AddWorkingStatusScreen extends StatefulWidget {
  const AddWorkingStatusScreen({super.key});

  @override
  State<AddWorkingStatusScreen> createState() => _AddWorkingStatusScreenState();
}

class _AddWorkingStatusScreenState extends State<AddWorkingStatusScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();

  bool _isEnableButton = false;
  bool _isSomethingWrong = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addWorkingStatus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = context.read<AdminWorkingStatusApiService>();
      final newStatusData = {
        "messageEn": _titleController.text.trim(),
        "messageAr": _detailsController.text.trim(),
        "isEnableButton": _isEnableButton,
        "isSomethingWrong": _isSomethingWrong,
        "appVersionCode": int.tryParse(_appVersionController.text.trim()) ?? 0,
      };
      await api.createWorkingStatus(newStatusData);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Working status added successfully!"),
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

      String errorMessage = "Failed to add working status. ";

      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection and try again.";
      } else if (e.toString().contains('permission')) {
        errorMessage += "You don't have permission to add working status.";
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
            onPressed: _addWorkingStatus,
          ),
        ),
      );

      debugPrint('Error adding working status: $e');
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
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
            style: TextStyle(fontSize: 12),
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: !_isLoading,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
                    left: value ? 10 : null,
                    right: value ? null : 10,
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
                    left: value ? 35 : 8,
                    top: 6,
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
          ),
        ],
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
            // selectedIndex: 6, // Current screen index
            // onItemTapped: (index) {
            //   // Navigate back to dashboard with selected index
            //   Navigator.of(context).pushReplacement(
            //     MaterialPageRoute(
            //       builder: (context) => DashboardScreen(initialIndex: 0),
            //     ),
            //   );
            // },
          ),

          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(),
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
                                        'Add Working Status',
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
                                    'Dashboard / Working Status List / Add Working Status',
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
                                        _buildTextField(
                                          label: "Working Title*",
                                          controller: _titleController,
                                          validator: (v) => v!.isEmpty
                                              ? "Enter working title"
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildTextField(
                                          label: "Working Details*",
                                          controller: _detailsController,
                                          maxLines: 4,
                                          validator: (v) => v!.isEmpty
                                              ? "Enter working details"
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildTextField(
                                          label: "App Version Code",
                                          controller: _appVersionController,
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSwitchField(
                                                label: "Enable Button",
                                                subtitle:
                                                    "Enable or disable the button functionality",
                                                value: _isEnableButton,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _isEnableButton = val;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: _buildSwitchField(
                                                label: "Something Wrong",
                                                subtitle:
                                                    "Indicate if there's an issue or error",
                                                value: _isSomethingWrong,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _isSomethingWrong = val;
                                                  });
                                                },
                                              ),
                                            ),
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
                                                          vertical: 8,
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
                                                      : _addWorkingStatus,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
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
                                                          "ADD WORKING STATUS",
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
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildImagePreview(),
                                    ),
                                    const SizedBox(height: 12),
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

  Widget _buildImagePreview() {
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
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }
}
