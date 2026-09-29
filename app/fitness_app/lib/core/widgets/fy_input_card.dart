import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum FyInputCardVariant { soft, outlined }

/// Card-style form field with a branded leading icon tile.
///
/// Validation errors render below the bordered field so they do not expand it.
class FyInputCard extends StatelessWidget {
  const FyInputCard({
    required this.label,
    required this.icon,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enabled = true,
    this.trailing,
    this.unit,
    this.autofillHints,
    this.variant = FyInputCardVariant.soft,
    super.key,
  }) : assert(trailing == null || unit == null);

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enabled;
  final Widget? trailing;
  final String? unit;
  final Iterable<String>? autofillHints;
  final FyInputCardVariant variant;

  static const double _fieldHeight = 48;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == FyInputCardVariant.outlined;

    return FormField<String>(
      initialValue: controller?.text,
      validator: (value) => validator?.call(controller?.text ?? value),
      builder: (field) {
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: hasError
                    ? Border.all(color: AppColors.error)
                    : (isOutlined
                          ? Border.all(color: AppColors.outlineVariant)
                          : null),
                boxShadow: isOutlined
                    ? null
                    : const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: SizedBox(
                height: _fieldHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: isOutlined ? 14 : 10),
                      child: ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: isOutlined ? 22 : 32,
                          child: isOutlined
                              ? Icon(
                                  icon,
                                  color: enabled
                                      ? AppColors.textMuted
                                      : AppColors.iconInactive,
                                  size: 20,
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: enabled
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: AppColors.onPrimary,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: keyboardType,
                        textInputAction: textInputAction,
                        onChanged: (value) {
                          field.didChange(value);
                          onChanged?.call(value);
                        },
                        onSubmitted: onFieldSubmitted,
                        obscureText: obscureText,
                        autocorrect: autocorrect,
                        enableSuggestions: enableSuggestions,
                        enabled: enabled,
                        autofillHints: autofillHints,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                        cursorColor: AppColors.primary,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: label,
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            height: 1.2,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconTheme(
                          data: const IconThemeData(
                            size: 22,
                            color: AppColors.primary,
                          ),
                          child: trailing!,
                        ),
                      )
                    else if (unit != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              unit!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
