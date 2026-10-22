import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_theme.dart';
import 'fy_motion.dart';

/// Visual role for [FyButton].
enum FyButtonVariant {
  /// Filled primary CTA (`#166246`) — one per screen.
  primary,

  /// Outlined — secondary actions.
  secondary,

  /// Outlined error — destructive / decline.
  danger,

  /// Tonal (primary soft fill) — quiet actions inside cards and lists.
  soft,
}

/// Density presets — radius [AppRadii.control] for every size.
enum FyButtonSize {
  /// Main action of a screen (52).
  large,

  /// Actions inside cards and lists (44).
  medium,
}

/// Shared Fitness Yoda action button.
///
/// Prefer this over raw [FilledButton] / [OutlinedButton] so height, pill
/// radius and variants stay consistent across the app.
class FyButton extends StatefulWidget {
  const FyButton({
    required this.label,
    required this.onPressed,
    this.variant = FyButtonVariant.primary,
    this.size = FyButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  });

  const FyButton.primary({
    required this.label,
    required this.onPressed,
    this.size = FyButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  }) : variant = FyButtonVariant.primary;

  const FyButton.secondary({
    required this.label,
    required this.onPressed,
    this.size = FyButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  }) : variant = FyButtonVariant.secondary;

  const FyButton.danger({
    required this.label,
    required this.onPressed,
    this.size = FyButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  }) : variant = FyButtonVariant.danger;

  const FyButton.soft({
    required this.label,
    required this.onPressed,
    this.size = FyButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  }) : variant = FyButtonVariant.soft;

  final String label;
  final VoidCallback? onPressed;
  final FyButtonVariant variant;
  final FyButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  static double heightFor(FyButtonSize size) => switch (size) {
    FyButtonSize.large => 52,
    FyButtonSize.medium => 44,
  };

  @override
  State<FyButton> createState() => _FyButtonState();
}

class _FyButtonState extends State<FyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final height = FyButton.heightFor(widget.size);
    final iconSize = widget.size == FyButtonSize.large ? 20.0 : 18.0;
    final fontSize = widget.size == FyButtonSize.large ? 16.0 : 15.0;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final reduceMotion = fyReduceMotion(context);

    final child = widget.isLoading
        ? SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _progressColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: iconSize),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final button = switch (widget.variant) {
      FyButtonVariant.primary || FyButtonVariant.soft => FilledButton(
        onPressed: enabled ? widget.onPressed : null,
        style: _filledStyle(height: height, fontSize: fontSize),
        child: child,
      ),
      FyButtonVariant.secondary || FyButtonVariant.danger => OutlinedButton(
        onPressed: enabled ? widget.onPressed : null,
        style: _outlinedStyle(height: height, fontSize: fontSize),
        child: child,
      ),
    };

    final scaled = reduceMotion
        ? button
        : Listener(
            onPointerDown: enabled ? (_) => _setPressed(true) : null,
            onPointerUp: (_) => _setPressed(false),
            onPointerCancel: (_) => _setPressed(false),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: FyMotion.press,
              curve: Curves.easeOut,
              child: button,
            ),
          );

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: height,
      child: scaled,
    );
  }

  Color get _progressColor => switch (widget.variant) {
    FyButtonVariant.primary => AppColors.onPrimary,
    FyButtonVariant.secondary => AppColors.primary,
    FyButtonVariant.danger => AppColors.error,
    FyButtonVariant.soft => AppColors.primary,
  };

  ButtonStyle _filledStyle({required double height, required double fontSize}) {
    final isSoft = widget.variant == FyButtonVariant.soft;
    return FilledButton.styleFrom(
      backgroundColor: isSoft ? AppColors.primarySoft : AppColors.primary,
      foregroundColor: isSoft ? AppColors.primary : AppColors.onPrimary,
      disabledBackgroundColor: isSoft
          ? AppColors.sunken
          : AppColors.primary.withValues(alpha: widget.isLoading ? 1 : 0.4),
      disabledForegroundColor: isSoft
          ? AppColors.textMuted
          : AppColors.onPrimary.withValues(alpha: 0.8),
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(0, height),
      maximumSize: Size(double.infinity, height),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
      ),
      textStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  ButtonStyle _outlinedStyle({
    required double height,
    required double fontSize,
  }) {
    final color = widget.variant == FyButtonVariant.danger
        ? AppColors.error
        : AppColors.primary;
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: color.withValues(alpha: 0.4),
      backgroundColor: AppColors.surface,
      minimumSize: Size(0, height),
      maximumSize: Size(double.infinity, height),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      side: BorderSide(
        color: widget.variant == FyButtonVariant.danger
            ? color
            : AppColors.borderStrong,
        width: 1.5,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
      ),
      textStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
