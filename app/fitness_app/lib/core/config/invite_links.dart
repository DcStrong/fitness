/// Deep link placeholders for QR invitations (roadmap open question #2).
///
/// HTTPS is encoded in QR by default (scanner-friendly).
/// Custom scheme is for in-app / OS deep link handling.
abstract final class InviteLinks {
  static const httpsBase = 'https://app.fitness-yoda.local/i';
  static const schemeBase = 'fitnessyoda://invite';

  static String httpsUrl(String token) => '$httpsBase/$token';

  static String deepLink(String token) => '$schemeBase/$token';

  /// Extracts token from HTTPS or custom-scheme invite URLs, or returns raw token.
  static String? extractToken(String? raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'fitnessyoda' &&
          uri.host == 'invite' &&
          uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments[uri.pathSegments.length - 2] == 'i') {
        return uri.pathSegments.last;
      }
      if (uri.pathSegments.isNotEmpty &&
          (uri.path.contains('/i/') || uri.path.contains('/invite/'))) {
        return uri.pathSegments.last;
      }
    }

    // Bare token (base64url-ish)
    if (RegExp(r'^[A-Za-z0-9_-]{16,}$').hasMatch(value)) {
      return value;
    }
    return null;
  }
}
