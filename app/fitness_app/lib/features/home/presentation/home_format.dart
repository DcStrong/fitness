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
