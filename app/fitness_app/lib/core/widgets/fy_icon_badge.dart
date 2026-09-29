import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Circular or squircle mint tile for icons on cards (hub, library, tags).
class FyIconBadge extends StatelessWidget {
  const FyIconBadge({
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.circle = true,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(16),
        ),
        child: Icon(icon, size: iconSize, color: AppColors.primary),
      ),
    );
  }
}
