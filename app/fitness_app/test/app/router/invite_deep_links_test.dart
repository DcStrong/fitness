import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/app/router/invite_deep_links.dart';
import 'package:fitness_app/core/config/invite_links.dart';

void main() {
  const token = 'Tol_BwmYjA4uIHMozUYMVMOETonzBAHerqjHzVAhvVE';

  group('inviteRouteForUri', () {
    test('https-ссылка стенда', () {
      expect(
        inviteRouteForUri(
          Uri.parse('https://app.149.154.64.173.sslip.io/i/$token'),
        ),
        '/i/$token',
      );
    });

    test('локальная http-ссылка', () {
      expect(
        inviteRouteForUri(Uri.parse('http://localhost:8080/i/$token')),
        '/i/$token',
      );
    });

    test('кастомная схема', () {
      expect(
        inviteRouteForUri(Uri.parse('fitnessyoda://invite/$token')),
        '/i/$token',
      );
    });

    test('посторонняя ссылка игнорируется', () {
      expect(inviteRouteForUri(Uri.parse('https://example.com/about')), isNull);
    });
  });

  test('extractToken принимает «голый» токен и пустое значение', () {
    expect(InviteLinks.extractToken(token), token);
    expect(InviteLinks.extractToken('  '), isNull);
    expect(InviteLinks.extractToken(null), isNull);
  });
}
