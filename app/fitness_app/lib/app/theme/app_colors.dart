import 'package:flutter/material.dart';

/// Fitness Yoda visual tokens — design system v2.
///
/// Source of truth: the «Fitness Yoda — дизайн-система» canvas (boards
/// «Основы» and «Компоненты»). One green for actions and selection, neutrals
/// with a green undertone, amber / red / blue only for statuses.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF166246);
  static const Color primaryPressed = Color(0xFF0F4A35);
  static const Color primarySoft = Color(0xFFE1F0E8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Secondary text on a primary fill.
  static const Color onPrimaryMuted = Color(0xFFC8E6D9);

  /// Accent on green fill only, 24 px and larger (≈2:1 on white).
  static const Color mint = Color(0xFF57CEA8);

  // Neutrals
  static const Color canvas = Color(0xFFF3F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sunken = Color(0xFFE9F0EC);
  static const Color border = Color(0xFFD9E4DE);
  static const Color borderStrong = Color(0xFFB9CCC2);

  // Text
  static const Color textPrimary = Color(0xFF1B2824);
  static const Color textSecondary = Color(0xFF51615A);
  static const Color textTertiary = Color(0xFF5C6C65);

  // Statuses: background + foreground pairs, contrast ≥ 5.5:1.
  static const Color confirmedBg = primarySoft;
  static const Color confirmedFg = primary;
  static const Color waitingBg = Color(0xFFFBEFCF);
  static const Color waitingFg = Color(0xFF7A4F00);
  static const Color doneBg = Color(0xFFE3EEF8);
  static const Color doneFg = Color(0xFF1D5C94);
  static const Color noShowBg = Color(0xFFFCE8E5);
  static const Color noShowFg = Color(0xFFA52A22);
  static const Color cancelledBg = sunken;
  static const Color cancelledFg = textSecondary;

  static const Color error = Color(0xFFA52A22);
  static const Color success = primary;

  /// Deadline / urgency accents (inbox countdown).
  static const Color warning = waitingFg;

  /// Level-1 elevation tint (cards); level 2 uses [shadowStrong].
  static const Color shadow = Color(0x0F166246);
  static const Color shadowStrong = Color(0x24166246);

  // Legacy aliases kept so screens compile while they move to DS v2 names.
  static const Color secondary = textTertiary;
  static const Color textMuted = textSecondary;
  static const Color iconInactive = textTertiary;
  static const Color mintSoft = primarySoft;
  static const Color softFill = sunken;
  static const Color actionFill = primarySoft;
  static const Color actionShadow = shadowStrong;
  static const Color outlineVariant = border;
}
