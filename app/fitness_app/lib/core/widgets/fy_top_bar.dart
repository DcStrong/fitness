import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shared authenticated top chrome: title + optional subtitle.
///
/// No notification bell in this wave. Use as [Scaffold.appBar].
class FyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FyTopBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  bool get _hasSubtitle {
    final value = subtitle?.trim();
    return value != null && value.isNotEmpty;
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final toolbar = _hasSubtitle ? 64.0 : kToolbarHeight;
    return Size.fromHeight(toolbar + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );

    final titleWidget = _hasSubtitle
        ? Column(
            crossAxisAlignment: centerTitle
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ],
          )
        : Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          );

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: titleWidget,
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: _hasSubtitle ? 64 : kToolbarHeight,
    );
  }
}
