import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Ссылки приглашений — это пути (`/i/<token>`), а не hash-фрагменты (`/#/i/...`).
  usePathUrlStrategy();
  runApp(const FitnessApp());
}
