import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'fy_button.dart';
import 'fy_motion.dart';

/// Fitness Yoda primary call-to-action — thin wrapper over [FyButton].
///
/// Prefer [FyButton.primary] for new call sites; this keeps auth/form APIs stable.
class FyPrimaryButton extends StatelessWidget {
  const FyPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.showTrailingArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final bool showTrailingArrow;

  @override
  Widget build(BuildContext context) {
    if (!showTrailingArrow) {
      return FyButton.primary(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        fullWidth: fullWidth,
      );
    }

    return _TrailingArrowPrimary(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }
}

/// Trailing-arrow layout is auth-specific; keep it local to this wrapper.
class _TrailingArrowPrimary extends StatefulWidget {
  const _TrailingArrowPrimary({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.fullWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<_TrailingArrowPrimary> createState() => _TrailingArrowPrimaryState();
}

class _TrailingArrowPrimaryState extends State<_TrailingArrowPrimary> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final reduceMotion = fyReduceMotion(context);
    final button = SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: FyButton.heightFor(FyButtonSize.large),
      child: FilledButton(
        onPressed: enabled ? widget.onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: widget.isLoading
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.8),
          minimumSize: Size(0, FyButton.heightFor(FyButtonSize.large)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            inherit: false,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: widget.isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: AppColors.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : widget.fullWidth
            ? Row(
                children: [
                  const SizedBox(width: 21),
                  const Spacer(),
                  Text(widget.label),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 21),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 21),
                ],
              ),
      ),
    );

    if (reduceMotion) return button;

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: FyMotion.press,
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
