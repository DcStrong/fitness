String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$dd.$mm.$yyyy $hh:$min';
}

String formatDateOnly(DateTime value) {
  final local = value.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  return '$dd.$mm.$yyyy';
}

/// Relative calendar label: сегодня / завтра / вчера / DD.MM.YY.
String formatRelativeCalendarDate(DateTime value, {DateTime? now}) {
  final local = DateTime(value.year, value.month, value.day);
  final clock = (now ?? DateTime.now()).toLocal();
  final today = DateTime(clock.year, clock.month, clock.day);
  final delta = local.difference(today).inDays;
  if (delta == 0) return 'сегодня';
  if (delta == 1) return 'завтра';
  if (delta == -1) return 'вчера';
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yy = (local.year % 100).toString().padLeft(2, '0');
  return '$dd.$mm.$yy';
}

/// Parses ISO datetime or `YYYY-MM-DD` for relative labels.
String? formatRelativeCalendarDateString(String? raw, {DateTime? now}) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      final parts = raw.split('-').map(int.parse).toList();
      return formatRelativeCalendarDate(
        DateTime(parts[0], parts[1], parts[2]),
        now: now,
      );
    }
    return formatRelativeCalendarDate(DateTime.parse(raw).toLocal(), now: now);
  } catch (_) {
    return raw;
  }
}

String formatTime(DateTime value) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$hh:$min';
}

/// Inbox / agenda line: `Сегодня · 18:00–19:00` or `22.07 · 18:00–19:00`.
String formatSlotDayRange(DateTime startsAt, DateTime endsAt, {DateTime? now}) {
  final start = startsAt.toLocal();
  final end = endsAt.toLocal();
  final clock = now?.toLocal() ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final day = DateTime(start.year, start.month, start.day);
  final dayLabel = day == today
      ? 'Сегодня'
      : day == today.add(const Duration(days: 1))
      ? 'Завтра'
      : '${start.day.toString().padLeft(2, '0')}.'
            '${start.month.toString().padLeft(2, '0')}';
  return '$dayLabel · ${formatTime(start)}–${formatTime(end)}';
}

/// Reply deadline: `Ответить до 21:30` (same calendar day) or with date.
String formatReplyBy(DateTime expiresAt, {DateTime? now}) {
  final expires = expiresAt.toLocal();
  final clock = now?.toLocal() ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final day = DateTime(expires.year, expires.month, expires.day);
  if (day == today) {
    return 'Ответить до ${formatTime(expires)}';
  }
  return 'Ответить до ${formatDateTime(expires)}';
}

String formatCountdown(Duration remaining) {
  if (remaining.isNegative) {
    remaining = Duration.zero;
  }
  final hours = remaining.inHours.toString().padLeft(2, '0');
  final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String initialsFromLabel(String label) {
  final parts = label
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final value = parts.first;
    return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }
  return ('${parts.first[0]}${parts[1][0]}').toUpperCase();
}
