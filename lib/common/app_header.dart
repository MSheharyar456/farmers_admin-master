import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:farmers_admin/auth/auth_screen.dart';
import 'package:farmers_admin/models/admin_user.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AdminServerAuthService>(context);
    final currentUser = authService.currentUser;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isTiny = w < 420;
          final isSmall = w >= 420 && w < 600;
          final isMedium = w >= 600 && w < 900;
          final showName = w >= 600;
          final horizontalPadding = (w * 0.03).clamp(12.0, 28.0);
          final avatarRadius = isTiny ? 10.0 : 12.0;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300, // light grey bottom border
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1), // subtle shadow
                  blurRadius: 1,
                  offset: Offset(0, 1), // shadow below
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Notification Icon
                Tooltip(
                  message: 'Notifications',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.5), width: 0.2),
                    ),
                    margin: EdgeInsets.all(5),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.black12;
                          }
                          return Colors.transparent;
                        }),
                      ),
                      icon: SvgPicture.asset(
                        "images/ic_farm_notification.svg",
                        width: 12,
                        height: 12,

                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
                SizedBox(width: isTiny ? 8 : 5),

                // Message Icon
                Tooltip(
                  message: 'Messages',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.5), width: 0.2),
                    ),
                    margin: EdgeInsets.all(5),
                    child: IconButton(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.black12;
                          }
                          return Colors.transparent;
                        }),
                      ),
                      icon: SvgPicture.asset(
                        "images/ic_farm_message.svg",
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
                SizedBox(width: isTiny ? 8 : 0),

                // User profile or Sign in
                if (currentUser != null)
                  _ProfileArea(
                    adminUser: currentUser,
                    avatarRadius: avatarRadius,
                    showName: showName,
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    child: const Text("Sign in"),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileArea extends StatefulWidget {
  final AdminUser adminUser;
  final double avatarRadius;
  final bool showName;

  const _ProfileArea({
    required this.adminUser,
    required this.avatarRadius,
    required this.showName,
  });

  @override
  State<_ProfileArea> createState() => _ProfileAreaState();
}

class _ProfileAreaState extends State<_ProfileArea> {
  double _buttonWidth = 50.0;
  final GlobalKey<PopupMenuButtonState<int>> _menuKey = GlobalKey();

  void _updateButtonWidth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() {
          _buttonWidth = box.size.width;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateButtonWidth();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.adminUser.displayName;

    final avatar = CircleAvatar(
      radius: widget.avatarRadius,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.asset(
          "images/profile.jpeg",
          fit: BoxFit.cover,
          width: widget.avatarRadius * 2,
          height: widget.avatarRadius * 2,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.5), width: 0.2),
      ),
      child: PopupMenuButton<int>(
        key: _menuKey,
        tooltip: 'Account menu',
        color: Colors.white,
        offset: const Offset(15, 40),
        onSelected: (value) async {
          if (value == 1) {
            // Navigate to profile
          } else if (value == 2) {
            final authService = Provider.of<AdminServerAuthService>(context, listen: false);
            await authService.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }
          }
        },
        itemBuilder: (context) {
          return [

            // PopupMenuItem(
            //   value: 2,
            //
            //   child: SizedBox(
            //     width: 150,
            //     child: const Text('Sign out'),
            //   ),
            // ),
          ];
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            if (widget.showName) const SizedBox(width: 10),
            if (widget.showName)
              Text(
                displayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

}