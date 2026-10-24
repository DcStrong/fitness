import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/invite_links.dart';

/// Маршрут приложения для входящей ссылки приглашения (`https://<хост>/i/<token>`
/// или `fitnessyoda://invite/<token>`); `null`, если это не приглашение.
String? inviteRouteForUri(Uri uri) {
  final token = InviteLinks.extractToken(uri.toString());
  return token == null ? null : '/i/$token';
}

/// Передаёт в роутер ссылки, которыми ОС открыла мобильное приложение
/// (Android App Links, iOS Universal Links, кастомная схема). На вебе не нужен:
/// браузер сам открывает URL, а роутер читает его (path-стратегия).
class InviteDeepLinkListener {
  InviteDeepLinkListener(this._router, {AppLinks? appLinks})
    : _appLinks = appLinks;

  final GoRouter _router;
  final AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    if (kIsWeb) {
      return;
    }
    final links = _appLinks ?? AppLinks();
    _subscription = links.uriLinkStream.listen(_handle);
    final initial = await links.getInitialLink();
    if (initial != null) {
      _handle(initial);
    }
  }

  void _handle(Uri uri) {
    final route = inviteRouteForUri(uri);
    if (route != null) {
      _router.go(route);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
