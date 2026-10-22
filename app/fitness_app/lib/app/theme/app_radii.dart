/// Corner radii — design system v2: one geometry for the whole app.
abstract final class AppRadii {
  /// Tags, small marks, bars.
  static const double tag = 8;

  /// Buttons, inputs, segmented controls, icon tiles.
  static const double control = 14;

  /// Cards and list groups.
  static const double card = 20;

  /// Bottom sheets and dialogs.
  static const double sheet = 28;

  /// Chips and navigation only.
  static const double pill = 999;

  // Legacy names.
  static const double sm = control;
  static const double md = control;
  static const double lg = card;
  static const double xl = sheet;
}

/// Spacing scale — step 4.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal screen padding.
  static const double screen = 20;

  /// Gap between cards in a list.
  static const double cardGap = 12;
}
