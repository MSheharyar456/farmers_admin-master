import 'package:farmers_admin/common/main_layout.dart';
import 'package:farmers_admin/screens/app_setting/widgets/sub_admin_card.dart';
import 'package:farmers_admin/screens/app_setting/widgets/super_admin_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userType != 'admin') {
      return const Scaffold(body: Center(child: Text("Access Denied")));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          // ✅ GREEN FOCUS BORDER
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),

          // ✅ Normal border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),

          // ✅ Error border
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),

          // ✅ Focused error border
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),

          // ✅ Label color when focused
          floatingLabelStyle: const TextStyle(color: Colors.green),
        ),
      ),
      child: MainLayout(
        userType: userType,
        child: Container(
          padding: const EdgeInsets.only(
            right: 30,
            left: 30,
            bottom: 30,
            top: 20,
          ),
          margin: EdgeInsets.only(top: 0),
          color: const Color(0xFFF5F6FA),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "App Settings",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // Responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: SuperAdminCard()),
                          const SizedBox(width: 30),
                          const Expanded(child: SubAdminCard()),
                        ],
                      );
                    } else {
                      return const Column(
                        children: [
                          SuperAdminCard(),
                          SizedBox(height: 30),
                          SubAdminCard(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
