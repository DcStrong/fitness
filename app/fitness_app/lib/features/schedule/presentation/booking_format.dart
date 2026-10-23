/// Labels for the student booking screen (DS v2 «Запись»).
library;

const _monthsNominative = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
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

/// «в понедельник», «во вторник», «в среду»…
const _weekdaysAccusative = [
  'в понедельник',
  'во вторник',
  'в среду',
  'в четверг',
  'в пятницу',
  'в субботу',
  'в воскресенье',
];

const _weekdaysShortTitle = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Month above the day strip: «Октябрь».
String formatBookingMonth(DateTime day) => _monthsNominative[day.month - 1];

/// Section above the slot grid: «Свободно сегодня», «Свободно в пятницу».
String formatBookingDayTitle(DateTime day, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final delta = target.difference(today).inDays;
  if (delta == 0) return 'Свободно сегодня';
  if (delta == 1) return 'Свободно завтра';
  if (delta > 1 && delta < 7) {
    return 'Свободно ${_weekdaysAccusative[day.weekday - 1]}';
  }
  return 'Свободно ${day.day} ${_monthsShort[day.month - 1]}';
}

/// Summary bar line: «Пт, 23 окт · 10:00».
String formatBookingSummary(DateTime start) {
  final local = start.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${_weekdaysShortTitle[local.weekday - 1]}, ${local.day} '
      '${_monthsShort[local.month - 1]} · $hh:$mm';
}
