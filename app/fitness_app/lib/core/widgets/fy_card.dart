import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';

/// DS v2 elevation level 1 — the one card shadow used everywhere.
const List<BoxShadow> fyShadowLevel1 = [
  BoxShadow(color: AppColors.shadow, blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0D166246), blurRadius: 16, offset: Offset(0, 4)),
];

/// DS v2 elevation level 2 — navigation bar and sheets.
const List<BoxShadow> fyShadowLevel2 = [
  BoxShadow(color: Color(0x14166246), blurRadius: 4, offset: Offset(0, 2)),
  BoxShadow(
    color: AppColors.shadowStrong,
    blurRadius: 32,
    offset: Offset(0, 12),
  ),
];

/// Shared Fitness Yoda card: white surface, 1 px border, level-1 shadow.
class FyCard extends StatelessWidget {
  const FyCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.card)),
    this.border = const Border.fromBorderSide(
      BorderSide(color: AppColors.border),
    ),
    this.boxShadow = fyShadowLevel1,
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
