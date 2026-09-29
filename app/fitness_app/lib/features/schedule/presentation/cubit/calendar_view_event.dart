import 'package:equatable/equatable.dart';

import '../../domain/calendar_range.dart';

/// UI intents for [CalendarBloc] (not domain calendar cards).
sealed class CalendarViewEvent extends Equatable {
  const CalendarViewEvent();

  @override
  List<Object?> get props => const [];
}

final class CalendarViewStarted extends CalendarViewEvent {
  const CalendarViewStarted();
}

final class CalendarViewRefreshed extends CalendarViewEvent {
  const CalendarViewRefreshed();
}

final class CalendarViewModeSelected extends CalendarViewEvent {
  const CalendarViewModeSelected(this.mode);

  final CalendarMode mode;

  @override
  List<Object?> get props => [mode];
}

final class CalendarViewPreviousPressed extends CalendarViewEvent {
  const CalendarViewPreviousPressed();
}

final class CalendarViewNextPressed extends CalendarViewEvent {
  const CalendarViewNextPressed();
}

final class CalendarViewTodayPressed extends CalendarViewEvent {
  const CalendarViewTodayPressed({this.now});

  final DateTime? now;

  @override
  List<Object?> get props => [now];
}

final class CalendarViewDateSelected extends CalendarViewEvent {
  const CalendarViewDateSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}
