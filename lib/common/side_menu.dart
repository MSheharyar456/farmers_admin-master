import 'package:farmers_admin/screens/app_setting/app_setting_screen.dart';
import 'package:farmers_admin/screens/ads_image.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:farmers_admin/screens/farming_tip/farmingTip.dart';
import 'package:farmers_admin/screens/user_management/user_screen.dart';
import 'package:farmers_admin/screens/user_management/deleted_users_screen.dart';
import 'package:farmers_admin/user_feedback/user_feedback_screen.dart';
import 'package:farmers_admin/screens/commission/commission_screen.dart';
import 'package:farmers_admin/screens/post_report/post_report_screen.dart';
import 'package:farmers_admin/screens/notify_users/notify_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/auth/auth_screen.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/screens/working_status/working_status_screen.dart';
import '../screens/post_management/post_management_screen.dart';
import '../screens/post_management/sold_posts_screen.dart';
import 'package:farmers_admin/screens/admin_chat/admin_chat_list_screen.dart';
import 'package:farmers_admin/screens/crash_reports/crash_reports_screen.dart';
import 'package:farmers_admin/utils/localization_helper.dart';

class SideMenu extends StatefulWidget {
  final String? userType;
  const SideMenu({super.key, this.userType});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int _activeIndex = -1;
  String? userType;

  @override
  void initState() {
    super.initState();
    _loadActiveIndex();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      print('hellow');
      userType = prefs.getString('userType');
      print("Loaded userType: $userType");
    });
  }

  Future<void> _loadActiveIndex() async {
    final prefs = await SharedPreferences.getInstance();

    /// When user logs in, we reset the menu highlight to Dashboard (index 0)
    bool isFreshLogin = prefs.getBool('isFreshLogin') ?? false;

    setState(() {
      if (isFreshLogin) {
        _activeIndex = 0; // Dashboard
        prefs.setInt('activeMenuIndex', 0);
        prefs.setBool('isFreshLogin', false);
      } else {
        _activeIndex = prefs.getInt('activeMenuIndex') ?? 0;
      }
    });
  }

  Future<void> _setActiveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeMenuIndex', index);
    setState(() {
      _activeIndex = index;
    });
  }

  void _navigateTo(BuildContext context, Widget screen, int index) async {
    await _setActiveIndex(index);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // No animation - direct transition
          },
          transitionDuration: Duration.zero, // No transition duration
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: 200,
      child: Container(
        color: appColors.sidebarBackground,
        child: Column(
          children: [
            // Scrollable items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 15,
                        bottom: 17,
                        left: 5,
                      ),
                      child: SvgPicture.asset(
                        "images/splash_green_2.svg",
                        width: 80,
                        height: 80,
                      ),
                    ),
                    // Menu Items
                    _buildMenuItem(
                      context,
                      index: 0,
                      svgPath: "images/ic_farm_home.svg",
                      text: "DASHBOARD",
                      onTap: () => _navigateTo(
                        context,
                        DashboardScreen(userType: userType),
                        0,
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      index: 1,
                      svgPath: "images/ic_farm_posts.svg",
                      text: "POSTS",
                      onTap: () =>
                          _navigateTo(context, const PostManagementScreen(), 1),
                    ),
                    _buildMenuItem(
                      context,
                      index: 10,
                      svgPath: "images/ic_farm_posts.svg",
                      text: "SOLD POSTS",
                      onTap: () =>
                          _navigateTo(context, const SoldPostsScreen(), 10),
                    ),

                    _buildMenuItem(
                      context,
                      index: 2,
                      svgPath: "images/ic_farm_customers.svg",
                      text: "USERS",
                      onTap: () => _navigateTo(context, const UserScreen(), 2),
                    ),
                    _buildMenuItem(
                      context,
                      index: 15,
                      icon: Icons.delete_forever,
                      text: "DELETED USERS",
                      onTap: () =>
                          _navigateTo(context, const DeletedUsersScreen(), 15),
                    ),
                    _buildMenuItem(
                      context,
                      index: 3,
                      svgPath: "images/ic_farm_feedback.svg",
                      text: "FEEDBACK",
                      onTap: () =>
                          _navigateTo(context, const UserFeedbackScreen(), 3),
                    ),
                    _buildMenuItem(
                      context,
                      index: 16,
                      icon: Icons.bug_report_outlined,
                      text: "CRASH REPORTS",
                      onTap: () =>
                          _navigateTo(context, const CrashReportsScreen(), 16),
                    ),
                    _buildMenuItem(
                      context,
                      index: 8,
                      svgPath: "images/setting1.svg",
                      text: "COMISSION",
                      onTap: () =>
                          _navigateTo(context, const CommissionScreen(), 8),
                    ),
                    _buildMenuItem(
                      context,
                      index: 9,
                      svgPath: "images/light1.svg",
                      text: "POST REPORT",
                      onTap: () =>
                          _navigateTo(context, const PostReportScreen(), 9),
                    ),
                    _buildMenuItem(
                      context,
                      index: 11,
                      svgPath: "images/ic_farm_feedback.svg",
                      text: "NOTIFY USERS",
                      onTap: () =>
                          _navigateTo(context, const NotifyUsersScreen(), 11),
                    ),
                    _buildMenuItem(
                      context,
                      index: 12,
                      svgPath:
                          "images/ic_farm_feedback.svg", // Reusing feedback icon for now
                      text: "USER CHAT",
                      onTap: () =>
                          _navigateTo(context, const AdminChatListScreen(), 12),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 12),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "SETTINGS",
                          style: TextStyle(
                            color: appColors.settingsHeaderText,
                            fontSize: 14,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      index: 4,
                      svgPath: "images/farmingTip.svg",
                      text: "Farming Tip",
                      onTap: () => _navigateTo(
                        context,
                        const FarmingTipManagementScreen(),
                        4,
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      index: 5,
                      svgPath: "images/adsImage.svg",
                      text: "Ads Image",
                      onTap: () =>
                          _navigateTo(context, const AdsImageScreen(), 5),
                    ),
                    _buildMenuItem(
                      context,
                      index: 6,
                      svgPath: "images/ic_farm_settings.svg",
                      text: "Working Status",
                      onTap: () => _navigateTo(
                        context,
                        const WorkingStatusManagementScreen(),
                        6,
                      ),
                    ),
                    userType == "admin"
                        ? _buildMenuItem(
                            context,
                            index: 7,
                            svgPath: "images/ic_farm_feedback.svg",
                            text: "APP SETTING",
                            onTap: () => _navigateTo(
                              context,
                              const AppSettingScreen(),
                              7,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10.0,
              ),
              child: ListTile(
                title: Row(
                  children: [
                    SizedBox(width: 10),
                    Icon(Icons.logout, color: Colors.green, size: 15),
                    SizedBox(width: 10),
                    const Text(
                      "LOGOUT",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                onTap: () async {
                  await showDeleteDialog(
                    context: context,
                    title: "Logout",
                    message: "Are you sure you want to log out?",
                    confirmText: "Yes, Logout",
                    cancelText: "Cancel",
                    showSuccessMessage: false,
                    onConfirm: () async {
                      final authService = Provider.of<AdminServerAuthService>(
                        context,
                        listen: false,
                      );
                      final userEmail = authService.currentUser?.email;

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      if (userEmail != null) {
                        await prefs.setString('lastLoggedInEmail', userEmail);
                      }

                      await authService.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully logout'),
                            backgroundColor: Colors.green,
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Language Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.language, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: AppLocalizations.currentLanguageCode,
                    dropdownColor: Colors.green.shade800,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    underline: const SizedBox(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await AppLocalizations.setLanguage(value);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    String? svgPath,
    IconData? icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final bool isActive = _activeIndex == index;

    final color = isActive ? appColors.brandColor : appColors.inactiveMenuText;
    final backgroundColor = isActive
        ? appColors.activeMenuBackground
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 32, // 🔹 manually set height
        width: 150,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 16, color: color)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
