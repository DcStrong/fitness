import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Selectable Fitness Yoda chip (weekday / mode / compact labels).
class FyChip extends StatelessWidget {
  const FyChip({
    required this.label,
    this.selected = false,
    this.onSelected,
    this.showCheckmark = false,
    this.leading,
    this.selectedColor,
    this.selectedForeground,
    this.backgroundColor,
    this.foregroundColor,
    this.outlined = false,
    this.compact = false,
    this.showBorder = true,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showCheckmark;
  final Widget? leading;
  final Color? selectedColor;
  final Color? selectedForeground;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool outlined;
  final bool compact;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    // DS v2 filter chip: selected = primary-soft fill + primary outline.
    final fg = selected
        ? (selectedForeground ?? AppColors.primary)
        : (foregroundColor ?? AppColors.textPrimary);
    final bg = selected
        ? (selectedColor ?? AppColors.primarySoft)
        : (backgroundColor ?? AppColors.surface);
    final borderColor = selected ? AppColors.primary : AppColors.border;

    final labelStyle = TextStyle(
      color: fg,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      fontSize: compact ? 12 : 14,
      height: 1.1,
    );

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          if (selected && showCheckmark && leading == null) ...[
            Icon(Icons.check, size: compact ? 12 : 16, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: labelStyle),
        ],
      ),
    );

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 11);

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: showBorder
            ? Border.all(color: borderColor, width: compact ? 1 : 1.5)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onSelected == null) {
      return box;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelected!(!selected),
        child: box,
      ),
    );
  }
}
