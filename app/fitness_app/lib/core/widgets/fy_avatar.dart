import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Initials for an avatar: two letters of the name, else of the email.
String personInitials({String? displayName, String? email}) {
  final name = displayName?.trim() ?? '';
  if (name.isNotEmpty) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w.characters.first).join();
    return letters.toUpperCase();
  }
  final mail = email?.trim() ?? '';
  if (mail.isNotEmpty) {
    final local = mail.split('@').first;
    return local.characters.take(2).toString().toUpperCase();
  }
  return '?';
}

/// DS v2 avatar: one tint for everyone (no random colours), initials inside.
class FyAvatar extends StatelessWidget {
  const FyAvatar({
    this.displayName,
    this.email,
    this.size = 44,
    this.onSurfaceTint = false,
    super.key,
  });

  final String? displayName;
  final String? email;
  final double size;

  /// White disc for avatars that sit on a primary-soft surface.
  final bool onSurfaceTint;

  @override
  Widget build(BuildContext context) {
    final initials = personInitials(displayName: displayName, email: email);
    return Semantics(
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: onSurfaceTint ? AppColors.surface : AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
