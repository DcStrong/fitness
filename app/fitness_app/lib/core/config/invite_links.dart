/// Разбор ссылок приглашений ученика.
///
/// Ссылку формирует бэкенд (`inviteUrl` = `INVITE_HTTPS_BASE` + `/i/<token>`,
/// `deepLink` = `fitnessyoda://invite/<token>`); клиент только извлекает токен.
abstract final class InviteLinks {
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
