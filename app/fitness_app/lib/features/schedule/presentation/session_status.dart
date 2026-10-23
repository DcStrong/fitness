import '../../../core/widgets/fy_status_chip.dart';

/// Status chip of a training session, shared by the calendar and the
/// session card: «Записан», «Проведено», «Не пришёл», «Отменено».
(FyStatus, String) sessionStatusChip(String? status) => switch (status) {
  'completed' => (FyStatus.done, 'Проведено'),
  'no_show' => (FyStatus.noShow, 'Не пришёл'),
  'cancelled' => (FyStatus.cancelled, 'Отменено'),
  _ => (FyStatus.confirmed, 'Записан'),
};
