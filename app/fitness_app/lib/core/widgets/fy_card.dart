import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shared Fitness Yoda soft surface.
class FyCard extends StatelessWidget {
  const FyCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.border,
    this.boxShadow = const [
      BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 6)),
    ],
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      // Transparent Material so ink from children (ListTile, InkWell) stays
      // visible above the card's background.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: onTap == null
            ? content
            : InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
      ),
    );
  }
}
