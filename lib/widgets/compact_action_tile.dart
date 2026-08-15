import 'package:flutter/material.dart';

class CompactActionTile extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const CompactActionTile({
    super.key,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 27,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: size,
        icon: Icon(icon, size: iconSize, color: iconColor),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
