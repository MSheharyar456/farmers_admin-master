import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget content;
  final String title;
  final Widget? sideMenu;

  const ResponsiveScaffold({
    super.key,
    required this.content,
    this.title = "Farmers Admin",
    this.sideMenu,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
            backgroundColor: Theme.of(context).extension<AppColors>()!.brandColor,
            title: Text(title),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          drawer: isDesktop
              ? null
              : Drawer(
            child: sideMenu ?? const SideMenu(),
          ),
          body: Row(
            children: [
              if (isDesktop)
                sideMenu ?? const SideMenu(),
              Expanded(
                child: Center(child: content),
              ),
            ],
          ),
        );
      },
    );
  }
}
