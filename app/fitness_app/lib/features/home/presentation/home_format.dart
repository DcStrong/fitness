const _months = [
  'ЯНВАРЯ',
  'ФЕВРАЛЯ',
  'МАРТА',
  'АПРЕЛЯ',
  'МАЯ',
  'ИЮНЯ',
  'ИЮЛЯ',
  'АВГУСТА',
  'СЕНТЯБРЯ',
  'ОКТЯБРЯ',
  'НОЯБРЯ',
  'ДЕКАБРЯ',
];

const _monthsShort = [
  'янв',
  'фев',
  'мар',
  'апр',
  'мая',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

const _weekdays = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

String formatHomeDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

String formatHomeWeekday(DateTime value) {
  final local = value.toLocal();
  return _weekdays[local.weekday - 1];
}

/// Compact header label: «Сегодня» plus the local calendar date.
String formatHomeDateChip(DateTime value) {
  final local = value.toLocal();
  return 'Сегодня, ${local.day} ${_monthsShort[local.month - 1]}';
}

String formatHomeTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Header line above the title: «Четверг, 22 октября».
String formatHomeHeaderDate(DateTime value) {
  final local = value.toLocal();
  return '${formatHomeWeekday(local)}, ${local.day} '
      '${_months[local.month - 1].toLowerCase()}';
}

/// Range label for the week bars: «19 – 25 октября» or «29 июн – 5 июл».
String formatHomeWeekRange(DateTime monday) {
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  if (monday.month == sunday.month) {
    return '${monday.day} – ${sunday.day} '
        '${_months[sunday.month - 1].toLowerCase()}';
  }
  return '${monday.day} ${_monthsShort[monday.month - 1]} – '
      '${sunday.day} ${_monthsShort[sunday.month - 1]}';
}

const _weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

String formatHomeWeekdayShort(DateTime value) =>
    _weekdaysShort[value.toLocal().weekday - 1];

/// Hero countdown split into a plain lead and an accented tail:
/// («Через », «25 мин»), («Идёт », «сейчас»), («Завтра в », «09:00»).
(String, String) formatHomeCountdown({
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  if (!now.isBefore(start) && now.isBefore(end)) return ('Идёт ', 'сейчас');
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(start.year, start.month, start.day);
  final dayDiff = day.difference(today).inDays;
  if (dayDiff == 0) {
    final minutes = start.difference(now).inMinutes.clamp(1, 24 * 60);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final tail = hours == 0
        ? '$rest мин'
        : rest == 0
        ? '$hours ч'
        : '$hours ч $rest мин';
    return ('Через ', tail);
  }
  if (dayDiff == 1) return ('Завтра в ', formatHomeTime(start));
  final lead =
      '${_weekdays[start.weekday - 1]}, ${start.day} '
      '${_monthsShort[start.month - 1]} в ';
  return (lead, formatHomeTime(start));
}
