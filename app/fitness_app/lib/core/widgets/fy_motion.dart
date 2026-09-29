import 'package:flutter/material.dart';

/// Whether motion polish should be skipped (accessibility / platform).
bool fyReduceMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}

/// Standard polish durations from design tokens (~200–250ms).
abstract final class FyMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration tab = Duration(milliseconds: 220);
  static const Duration panel = Duration(milliseconds: 240);
  static const Duration daySwitch = Duration(milliseconds: 200);
}
