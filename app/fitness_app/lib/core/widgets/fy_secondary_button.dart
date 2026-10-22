import 'package:flutter/material.dart';

import 'fy_button.dart';

/// Fitness Yoda secondary (outlined) action — thin wrapper over [FyButton].
class FySecondaryButton extends StatelessWidget {
  const FySecondaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.size = FyButtonSize.large,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final FyButtonSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FyButton.secondary(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      fullWidth: fullWidth,
      size: size,
      icon: icon,
    );
  }
}
