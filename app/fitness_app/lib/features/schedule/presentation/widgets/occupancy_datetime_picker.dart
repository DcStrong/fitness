import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../booking_requests/data/booking_request_models.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_events.dart';
import '../../domain/calendar_range.dart';
import '../schedule_format.dart';
import 'calendar_month_view.dart';
import 'calendar_period_format.dart';

/// Opens a month occupancy calendar, then a time picker.
/// Returns a local [DateTime] or null if cancelled.
Future<DateTime?> showOccupancyDateTimePicker({
  required BuildContext context,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _OccupancyPickerSheet(initialDate: initialDate ?? DateTime.now()),
  );
}

class _OccupancyPickerSheet extends StatefulWidget {
  const _OccupancyPickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_OccupancyPickerSheet> createState() => _OccupancyPickerSheetState();
}

class _OccupancyPickerSheetState extends State<_OccupancyPickerSheet> {
  late DateTime _anchorDate;
  late DateTime _selectedDate;
  List<CalendarEvent> _events = const [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _anchorDate = calendarDateOnly(widget.initialDate);
    _selectedDate = _anchorDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final range = rangeForMode(CalendarMode.month, _anchorDate);
    try {
      final schedule = context.read<ScheduleRepository>();
      final booking = context.read<BookingRequestsRepository>();
      final sessions = await schedule.listSessions(
        from: range.start,
        to: range.end,
      );
      final slots = await schedule.listOwnSlots(
        from: range.start,
        to: range.end,
      );
      List<BookingRequest> requests = const [];
      try {
        final page = await booking.inbox(
          page: 1,
          limit: 50,
          status: BookingRequestStatus.pending,
        );
        requests = page.items.where((request) {
          final start = request.requestedSlot.startsAt.toLocal();
          final end = request.requestedSlot.endsAt.toLocal();
          return start.isBefore(range.end) && end.isAfter(range.start);
        }).toList();
      } catch (_) {
        // Occupancy without requests is still useful.
      }
      if (!mounted) return;
      setState(() {
        _events = mapCalendarEvents(
          sessions: sessions,
          slots: slots,
          requests: requests,
          range: range,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _shiftMonth(int direction) async {
    final next = shiftAnchor(CalendarMode.month, _anchorDate, direction);
    setState(() {
      _anchorDate = next;
      if (_selectedDate.year != next.year ||
          _selectedDate.month != next.month) {
        _selectedDate = calendarDateOnly(next);
      }
    });
    await _loadMonth();
  }

  Future<void> _confirmTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    Navigator.pop(
      context,
      DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выберите дату с учётом занятости',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Отмечены тренировки, свободные слоты и ожидающие заявки.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  key: const Key('occupancy-picker-prev'),
                  onPressed: _loading ? null : () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    formatCalendarPeriodTitle(CalendarMode.month, _anchorDate),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('occupancy-picker-next'),
                  onPressed: _loading ? null : () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (_error != null) ...[
              FyInfoBanner(message: _error!, icon: Icons.error_outline),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: CalendarMonthView(
                        key: const Key('occupancy-picker-month'),
                        anchorDate: _anchorDate,
                        selectedDate: _selectedDate,
                        events: _events,
                        onSelectDate: (day) {
                          setState(() {
                            _selectedDate = calendarDateOnly(day);
                            if (day.month != _anchorDate.month ||
                                day.year != _anchorDate.year) {
                              _anchorDate = calendarDateOnly(day);
                              _loadMonth();
                            }
                          });
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выбрано: ${formatDateOnly(_selectedDate)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            FyButton.primary(
              key: const Key('occupancy-picker-confirm-time'),
              label: 'Выбрать время',
              size: FyButtonSize.medium,
              onPressed: _loading ? null : _confirmTime,
            ),
          ],
        ),
      ),
    );
  }
}
