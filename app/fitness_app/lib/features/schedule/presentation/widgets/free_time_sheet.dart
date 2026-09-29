import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_date_picker.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../data/schedule_repository.dart';
import '../schedule_calendar_sync.dart';
import '../schedule_format.dart';

class FreeTimeSheet extends StatefulWidget {
  const FreeTimeSheet({
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    super.key,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
  }) {
    final repository = context.read<ScheduleRepository>();
    final calendarSync = context.read<ScheduleCalendarSync>();

    return showFyBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ScheduleRepository>.value(value: repository),
          RepositoryProvider<ScheduleCalendarSync>.value(value: calendarSync),
        ],
        child: FreeTimeSheet(
          initialDate: initialDate,
          initialStartTime: initialStartTime,
          initialEndTime: initialEndTime,
        ),
      ),
    );
  }

  @override
  State<FreeTimeSheet> createState() => _FreeTimeSheetState();
}

class _FreeTimeSheetState extends State<FreeTimeSheet> {
  static const _timeUnavailableError = 'Окончание должно быть позже начала';

  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _mode = 'offline';
  String? _inlineError;
  String? _apiError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    if (widget.initialStartTime != null && widget.initialEndTime != null) {
      _startTime = widget.initialStartTime!;
      _endTime = widget.initialEndTime!;
      return;
    }
    final end = now.add(const Duration(hours: 1));
    _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
  }

  DateTime get _startsAt => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _startTime.hour,
    _startTime.minute,
  );

  DateTime get _endsAt => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _endTime.hour,
    _endTime.minute,
  );

  bool get _isEndAfterStart => _endsAt.isAfter(_startsAt);

  String _formatLocalDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm.${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showFyDatePicker(
      context: context,
      title: 'Дата свободного слота',
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _inlineError = null;
        _apiError = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _inlineError = _isEndAfterStart ? null : _timeUnavailableError;
        _apiError = null;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _inlineError = _isEndAfterStart ? null : _timeUnavailableError;
        _apiError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_isEndAfterStart) {
      setState(() => _inlineError = _timeUnavailableError);
      return;
    }

    setState(() {
      _submitting = true;
      _apiError = null;
      _inlineError = null;
    });

    try {
      await context.read<ScheduleRepository>().createSlot(
        startsAt: _startsAt,
        endsAt: _endsAt,
        mode: _mode,
      );
      if (!mounted) return;
      context.read<ScheduleCalendarSync>().notifyChanged();
      Navigator.pop(context, _startsAt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _apiError = error is ApiException
            ? error.message
            : 'Не удалось создать слот';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Добавить свободное время',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_formatLocalDate(_date)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickStartTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(formatTime(_startsAt)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickEndTime,
                    icon: const Icon(Icons.access_time_filled),
                    label: Text(formatTime(_endsAt)),
                  ),
                ),
              ],
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 8),
              Text(
                _inlineError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'online',
                  label: Text('Онлайн', key: Key('free-time-mode-online')),
                ),
                ButtonSegment(
                  value: 'offline',
                  label: Text('Очно', key: Key('free-time-mode-offline')),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _submitting
                  ? null
                  : (selection) => setState(() => _mode = selection.first),
            ),
            if (_apiError != null) ...[
              const SizedBox(height: 8),
              FyInfoBanner(
                message: _apiError!,
                icon: Icons.error_outline_rounded,
              ),
            ],
            const SizedBox(height: 20),
            FyPrimaryButton(
              key: const Key('free-time-submit'),
              label: 'Добавить',
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}
