import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';

/// DS v2 header action: a 44 px bordered square with one icon
/// (back, QR invite, recurring, history, chat).
class FySquareIconButton extends StatelessWidget {
  const FySquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.buttonKey,
    this.color = AppColors.textPrimary,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Key on the tappable area, for tests.
  final Key? buttonKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: shape.copyWith(side: const BorderSide(color: AppColors.border)),
        child: InkWell(
          key: buttonKey,
          customBorder: shape,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
