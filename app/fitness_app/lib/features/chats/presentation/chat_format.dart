import '../data/chat_models.dart';

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

const _weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
const _weekdaysTitle = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

String formatChatTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// List row time: «10:12» today, «вчера», weekday within a week, else «21.10».
String formatChatListTime(DateTime value, {required DateTime now}) {
  final local = value.toLocal();
  final days = _day(now).difference(_day(local)).inDays;
  if (days <= 0) return formatChatTime(local);
  if (days == 1) return 'вчера';
  if (days < 7) return _weekdaysShort[local.weekday - 1];
  return '${local.day.toString().padLeft(2, '0')}.'
      '${local.month.toString().padLeft(2, '0')}';
}

/// Day divider: «Сегодня», «Вчера», «21 октября» (+ year if not current).
String formatChatDay(DateTime value, {required DateTime now}) {
  final local = value.toLocal();
  final days = _day(now).difference(_day(local)).inDays;
  if (days == 0) return 'Сегодня';
  if (days == 1) return 'Вчера';
  final base = '${local.day} ${_monthsGenitive[local.month - 1]}';
  return local.year == now.year ? base : '$base ${local.year}';
}

/// «Ср, 21 октября» for system cards.
String formatChatSessionDate(DateTime value) {
  final local = value.toLocal();
  return '${_weekdaysTitle[local.weekday - 1]}, '
      '${local.day} ${_monthsGenitive[local.month - 1]}';
}

/// «сегодня, 11:00» / «завтра, 9:30» / «ср, 21 октября, 11:00».
String formatChatNextSession(DateTime value, {required DateTime now}) {
  final local = value.toLocal();
  final days = _day(local).difference(_day(now)).inDays;
  final time = formatChatTime(local);
  if (days == 0) return 'сегодня, $time';
  if (days == 1) return 'завтра, $time';
  return '${_weekdaysShort[local.weekday - 1]}, '
      '${local.day} ${_monthsGenitive[local.month - 1]}, $time';
}

String chatSystemTitle(ChatMessage message) => switch (message.systemType) {
  ChatSystemType.sessionBooked => 'Запись на занятие',
  ChatSystemType.sessionCancelled => 'Занятие отменено',
  ChatSystemType.sessionRescheduled => 'Занятие перенесено',
  ChatSystemType.occurrenceSkipped => 'Занятие пропущено',
  ChatSystemType.requestAccepted => 'Заявка принята',
  ChatSystemType.requestAlternate => 'Предложено другое время',
  ChatSystemType.requestRejected => 'Заявка отклонена',
  ChatSystemType.unknown || null => message.body,
};

/// One-line preview for the conversation list.
String chatPreview(ChatMessage message) =>
    message.isSystem ? chatSystemTitle(message) : message.body;
