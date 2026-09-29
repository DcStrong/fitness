import 'package:flutter/material.dart';

/// Fitness Yoda visual tokens.
///
/// Keep these values aligned with `app/design/tokens.md`.
abstract final class AppColors {
  static const Color primary = Color(0xFF166246);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF1F7F5);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color secondary = Color(0xFF6F9E8F);
  static const Color mint = Color(0xFF57CEA8);
  static const Color mintSoft = Color(0x2957CEA8);
  static const Color textMuted = Color(0x992E2E2E);
  static const Color iconInactive = Color(0xFF9AA8A2);
  static const Color success = primary;
  static const Color error = Color(0xFFC62828);

  /// Deadline / urgency accents (inbox countdown).
  static const Color warning = Color(0xFFC47A2C);

  /// Quiet filled actions (availability “copy”, soft CTAs).
  static const Color softFill = Color(0xFFF3EDE4);

  /// Raised action tiles on mint canvas (student hub quick actions).
  static const Color actionFill = Color(0xFFE4F7F1);
  static const Color actionShadow = Color(0x33166246);

  static const Color outlineVariant = Color(0x4D6F9E8F);
  static const Color shadow = Color(0x14000000);
}
