import 'package:farmers_admin/auth/auth_screen.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:farmers_admin/constants/app_colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: 230,
      child: Container(
        color: appColors.sidebarBackground,
        child: Column(
          children: [
            // ------- Scrollable content -------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 20.0,
                        bottom: 30.0,
                        start: 5,
                      ),
                      child: SvgPicture.asset(
                        "images/splash_green_2.svg",
                        semanticsLabel: "Your crop icon",
                        width: 140,
                        height: 140,
                      ),
                    ),

                    _buildMenuItem(
                      context: context,
                      svgPath: "images/ic_farm_home.svg",
                      text: 'DASHBOARD',
                      isActive: selectedIndex == 0,
                      onTap: () => onItemTapped(0),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/ic_farm_posts.svg",
                      text: 'POSTS',
                      isActive: selectedIndex == 1,
                      onTap: () => onItemTapped(1),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/ic_farm_customers.svg",
                      text: 'USERS',
                      isActive: selectedIndex == 2,
                      onTap: () => onItemTapped(2),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/ic_farm_feedback.svg",
                      text: 'FEEDBACK',
                      isActive: selectedIndex == 3,
                      onTap: () => onItemTapped(3),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 10, bottom: 12.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'SETTINGS',
                          style: TextStyle(
                            color: appColors.settingsHeaderText,
                            fontSize: 16,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/farmingTip.svg",
                      text: 'Farming Tip',
                      isActive: selectedIndex == 4,
                      onTap: () => onItemTapped(4),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/adsImage.svg",
                      text: 'Ads Image',
                      isActive: selectedIndex == 5,
                      onTap: () => onItemTapped(5),
                    ),
                    _buildMenuItem(
                      context: context,
                      svgPath: "images/ic_farm_settings.svg",
                      text: 'Working Status',
                      isActive: selectedIndex == 6,
                      onTap: () => onItemTapped(6),
                    ),
                  ],
                ),
              ),
            ),

            // ------- Sticky Logout Button -------
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10.0),
              child: _buildMenuItem1(
                context: context,
                icon: Icons.logout,
                text: 'LOGOUT',
                isActive: false,
                iconColor: Colors.green,
                textColor: Colors.green,
                onTap: () async {
                  await showDeleteDialog(
                    context: context,
                    title: "Logout",
                    message: "Are you sure you want to log out?",
                    confirmText: "Yes, Logout",
                    cancelText: "Cancel",
                    onConfirm: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                              (route) => false,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String svgPath,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final color = isActive ? appColors.brandColor : appColors.inactiveMenuText;
    final backgroundColor =
    isActive ? appColors.activeMenuBackground : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          svgPath,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        ),
        title: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItem1({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
