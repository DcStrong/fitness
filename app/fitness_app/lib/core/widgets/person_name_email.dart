import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Primary label: display name, else email, else [fallback].
String personPrimaryLabel({
  String? displayName,
  String? email,
  String fallback = '—',
}) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final mail = email?.trim();
  if (mail != null && mail.isNotEmpty) return mail;
  return fallback;
}

/// Email caption only when a real display name is present (avoid duplicate).
String? personEmailCaption({String? displayName, String? email}) {
  final name = displayName?.trim();
  final mail = email?.trim();
  if (name == null || name.isEmpty) return null;
  if (mail == null || mail.isEmpty) return null;
  return mail;
}

/// Name (bold) + optional tiny gray email under it.
class PersonNameEmail extends StatelessWidget {
  const PersonNameEmail({
    required this.displayName,
    this.email,
    this.fallback = '—',
    this.primaryStyle,
    this.maxLines = 1,
    this.dense = false,
    super.key,
  });

  final String? displayName;
  final String? email;
  final String fallback;
  final TextStyle? primaryStyle;
  final int maxLines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final primary = personPrimaryLabel(
      displayName: displayName,
      email: email,
      fallback: fallback,
    );
    final caption = personEmailCaption(displayName: displayName, email: email);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style:
              primaryStyle ??
              (dense
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    )
                  : theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
        ),
        if (caption != null) ...[
          SizedBox(height: dense ? 1 : 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: dense ? 10 : 11,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}
