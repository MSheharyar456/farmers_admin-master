import 'package:farmers_admin/common/main_layout.dart';
import 'package:farmers_admin/screens/app_setting/widgets/sub_admin_card.dart';
import 'package:farmers_admin/screens/app_setting/widgets/super_admin_card.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key});

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {
  String? userType;
  bool _isLoading = true;
  bool _superAdminLoading = true;
  bool _subAdminLoading = true;

  bool get _isContentLoading => _superAdminLoading || _subAdminLoading;
  bool get _showOverlay => _isLoading || _isContentLoading;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userType = prefs.getString('userType');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          floatingLabelStyle: const TextStyle(color: Colors.green),
        ),
      ),
      child: MainLayout(
        userType: userType,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                right: 30,
                left: 30,
                bottom: 30,
                top: 20,
              ),
              margin: const EdgeInsets.only(top: 0),
              color: const Color(0xFFF5F6FA),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isLoading && userType != 'admin')
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: Text("Access Denied")),
                      )
                    else ...[
                      const Text(
                        "App Settings",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SuperAdminCard(
                                    onLoadingChanged: (value) {
                                      if (!mounted) return;
                                      setState(() => _superAdminLoading = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: SubAdminCard(
                                    onLoadingChanged: (value) {
                                      if (!mounted) return;
                                      setState(() => _subAdminLoading = value);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              SuperAdminCard(
                                onLoadingChanged: (value) {
                                  if (!mounted) return;
                                  setState(() => _superAdminLoading = value);
                                },
                              ),
                              const SizedBox(height: 30),
                              SubAdminCard(
                                onLoadingChanged: (value) {
                                  if (!mounted) return;
                                  setState(() => _subAdminLoading = value);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showOverlay)
              const Positioned.fill(
                child: LoadingOverlay(text: 'Loading...', showBackdrop: true),
              ),
          ],
        ),
      ),
    );
  }
}
