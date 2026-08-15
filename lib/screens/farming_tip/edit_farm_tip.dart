import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/farming_tip_model.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:farmers_admin/services/farming_tip_api_service.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditFarmingTipScreen extends StatefulWidget {
  final FarmingTip tip;

  const EditFarmingTipScreen({super.key, required this.tip});

  @override
  State<EditFarmingTipScreen> createState() => _EditFarmingTipScreenState();
}

class _EditFarmingTipScreenState extends State<EditFarmingTipScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _englishController;
  late TextEditingController _arabicController;
  late TextEditingController _germanController;
  late TextEditingController _turkishController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _englishController = TextEditingController(
      text: widget.tip.farmingTipEnglish ?? '',
    );
    _arabicController = TextEditingController(
      text: widget.tip.farmingTipArabic ?? '',
    );
    _germanController = TextEditingController(
      text: widget.tip.farmingTipGerman ?? '',
    );
    _turkishController = TextEditingController(
      text: widget.tip.farmingTipTurkish ?? '',
    );
  }

  @override
  void dispose() {
    _englishController.dispose();
    _arabicController.dispose();
    _germanController.dispose();
    _turkishController.dispose();
    super.dispose();
  }

  Future<void> _updateFarmingTip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = context.read<FarmingTipApiService>();
      await service.updateFarmingTip(
        farmingTipEnglish: _englishController.text.trim(),
        farmingTipArabic: _arabicController.text.trim(),
        farmingTipGerman: _germanController.text.trim(),
        farmingTipTurkish: _turkishController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farming tip updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      String errorMessage = "Failed to update farming tip. ";
      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection and try again.";
      } else if (e.toString().contains('permission')) {
        errorMessage += "You don't have permission to update this tip.";
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
            onPressed: _updateFarmingTip,
          ),
        ),
      );
      debugPrint('Error updating farming tip: $e');
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 3,
    TextDirection textDirection = TextDirection.ltr,
    String? hintText,
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
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(fontSize: 12),
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          textDirection: textDirection,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hintText,
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
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        height: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SideMenu(
              // selectedIndex: 4, // Current screen index
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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppHeader(),
                          Container(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: [
                                // Header Section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  : () =>
                                                        Navigator.pop(context),
                                            ),
                                            Text(
                                              'Edit Farming Tip',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineLarge
                                                  ?.copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Dashboard / Farming Tips List / Edit Tip',
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

                                // Main Content Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Side - Form (75%)
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // English and Arabic Row
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildTextField(
                                                      label: 'English Tip*',
                                                      controller:
                                                          _englishController,
                                                      hintText:
                                                          'Enter farming tip in English...',
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty) {
                                                          return 'Please enter English tip';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _buildTextField(
                                                      label:
                                                          'Arabic Tip (العربية)*',
                                                      controller:
                                                          _arabicController,
                                                      hintText:
                                                          'أدخل نصيحة الزراعة بالعربية...',
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty) {
                                                          return 'Please enter Arabic tip';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),

                                              // German and Turkish Row
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildTextField(
                                                      label:
                                                          'German Tip (Deutsch)*',
                                                      controller:
                                                          _germanController,
                                                      hintText:
                                                          'Geben Sie den Landwirtschaftstipp auf Deutsch ein...',
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty) {
                                                          return 'Please enter German tip';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _buildTextField(
                                                      label:
                                                          'Turkish Tip (Türkçe)*',
                                                      controller:
                                                          _turkishController,
                                                      hintText:
                                                          'Türkçe tarım ipucunu girin...',
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value
                                                                .trim()
                                                                .isEmpty) {
                                                          return 'Please enter Turkish tip';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 32),

                                              // Action Buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 38,
                                                      child: OutlinedButton(
                                                        onPressed: _isLoading
                                                            ? null
                                                            : () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 5,
                                                              ),
                                                          side: BorderSide(
                                                            color: Colors
                                                                .grey[400]!,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  5,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'CANCEL',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black54,
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
                                                      height: 38,
                                                      child: ElevatedButton(
                                                        onPressed: _isLoading
                                                            ? null
                                                            : _updateFarmingTip,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 5,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        child: _isLoading
                                                            ? const SizedBox(
                                                                height: 15,
                                                                width: 15,
                                                                child: CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                              )
                                                            : const Text(
                                                                'SAVE CHANGES',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
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

                                    // Right Side - Tip Info Card (25%)
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.info_outline,
                                                    color:
                                                        Colors.green.shade700,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Expanded(
                                                  child: Text(
                                                    'Tip Information',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // Divider
                                            Divider(
                                              color: Colors.grey.shade200,
                                              height: 1,
                                            ),
                                            const SizedBox(height: 20),

                                            // Tip ID
                                            _buildInfoRow(
                                              icon: Icons.tag,
                                              label: 'Tip ID',
                                              value: widget.tip.tipId ?? 'N/A',
                                            ),
                                            const SizedBox(height: 16),

                                            // Languages Count
                                            _buildInfoRow(
                                              icon: Icons.language,
                                              label: 'Languages',
                                              value: '4 Languages',
                                            ),
                                            const SizedBox(height: 20),

                                            // Note Box
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.blue.shade100,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.lightbulb_outline,
                                                    color: Colors.blue.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Make sure all language versions convey the same agricultural advice.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .blue
                                                            .shade900,
                                                        height: 1.4,
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
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Positioned.fill(child: LoadingOverlay()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
