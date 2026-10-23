import '../../domain/calendar_range.dart';

const _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

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

const weekdayShortRu = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

const _weekdayLongRu = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];

String formatCalendarDayTitle(DateTime date) {
  final day = calendarDateOnly(date);
  final weekday = _weekdayLongRu[mondayBasedWeekday(day)];
  return '$weekday, ${day.day} ${_monthsGenitive[day.month - 1]}';
}

/// Line under the toolbar title: «Четверг · сегодня», «Неделя 19–25»…
String formatCalendarPeriodSubtitle(
  CalendarMode mode,
  DateTime anchor,
  DateTime now,
) {
  final day = calendarDateOnly(anchor);
  switch (mode) {
    case CalendarMode.day:
      final weekday = _weekdayLongRu[mondayBasedWeekday(day)];
      final today = calendarDateOnly(now);
      final diff = day.difference(today).inDays;
      final relative = switch (diff) {
        0 => ' · сегодня',
        1 => ' · завтра',
        -1 => ' · вчера',
        _ => '',
      };
      return '$weekday$relative';
    case CalendarMode.week:
      return 'Неделя';
    case CalendarMode.month:
      return 'Месяц';
  }
}

String formatCalendarPeriodTitle(CalendarMode mode, DateTime anchor) {
  final day = calendarDateOnly(anchor);
  switch (mode) {
    case CalendarMode.day:
      // Compact title between day chevrons (full weekday title stays under strip).
      return '${day.day} ${_monthsGenitive[day.month - 1]}';
    case CalendarMode.week:
      final days = daysInWeek(day);
      final start = days.first;
      final end = days.last;
      if (start.month == end.month) {
        return '${start.day}–${end.day} ${_monthsGenitive[start.month - 1]}';
      }
      return '${start.day} ${_monthsGenitive[start.month - 1]} – '
          '${end.day} ${_monthsGenitive[end.month - 1]}';
    case CalendarMode.month:
      return '${_monthsNominative[day.month - 1]} ${day.year}';
  }
}

String calendarDayKey(DateTime date) {
  final d = calendarDateOnly(date);
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}
