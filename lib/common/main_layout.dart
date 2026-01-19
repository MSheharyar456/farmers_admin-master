import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String? userType;

  const MainLayout({super.key, required this.child, this.userType});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Static Sidebar
          SideMenu(userType: widget.userType),

          // Content Area with animation
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static App Header
                const AppHeader(),

                // Animated Content Area
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
