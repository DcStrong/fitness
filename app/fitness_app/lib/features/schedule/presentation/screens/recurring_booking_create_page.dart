import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_input_card.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_search_select_field.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/schedule_repository.dart';
import '../cubit/recurring_booking_cubit.dart';
import '../schedule_calendar_sync.dart';
import '../widgets/student_search_select.dart';
import '../widgets/weekday_multi_picker.dart';
import '../../../../core/widgets/fy_top_bar.dart';

/// Prefill when opening create from calendar empty hour or open slot.
class RecurringBookingPrefill {
  const RecurringBookingPrefill({this.weekdays, this.startMinute, this.mode});

  factory RecurringBookingPrefill.fromLocalDateTime(
    DateTime local, {
    String? mode,
  }) {
    return RecurringBookingPrefill(
      weekdays: {local.weekday},
      startMinute: local.hour * 60 + local.minute,
      mode: mode,
    );
  }

  /// ISO weekdays 1..7 (Mon..Sun). When set, only these days are pre-selected.
  final Set<int>? weekdays;
  final int? startMinute;
  final String? mode;

  TimeOfDay? get timeOfDay {
    final minute = startMinute;
    if (minute == null) return null;
    return TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
  }
}

class RecurringBookingCreatePage extends StatelessWidget {
  const RecurringBookingCreatePage({this.prefill, super.key});

  final RecurringBookingPrefill? prefill;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecurringBookingCubit(
        scheduleRepository: context.read<ScheduleRepository>(),
        invitationsRepository: context.read<InvitationsRepository>(),
      )..loadCreateForm(),
      child: _RecurringBookingCreateView(prefill: prefill),
    );
  }
}

class _RecurringBookingCreateView extends StatefulWidget {
  const _RecurringBookingCreateView({this.prefill});

  final RecurringBookingPrefill? prefill;

  @override
  State<_RecurringBookingCreateView> createState() =>
      _RecurringBookingCreateViewState();
}

class _RecurringBookingCreateViewState
    extends State<_RecurringBookingCreateView> {
  String? _studentId;
  late final Set<int> _weekdays;
  late TimeOfDay _time;
  late String _mode;
  late final TextEditingController _horizonController;
  bool _horizonLoaded = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    _weekdays = prefill?.weekdays != null
        ? Set<int>.from(prefill!.weekdays!)
        : {1, 3, 5};
    _time = prefill?.timeOfDay ?? const TimeOfDay(hour: 18, minute: 0);
    _mode = prefill?.mode ?? 'offline';
    _horizonController = TextEditingController(text: '8');
    _loadDefaultHorizon();
  }

  @override
  void dispose() {
    _horizonController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultHorizon() async {
    try {
      final settings = await context
          .read<ScheduleRepository>()
          .getAvailabilitySettings();
      if (!mounted || _horizonLoaded) return;
      setState(() {
        _horizonController.text = '${settings.horizonWeeks}';
        _horizonLoaded = true;
      });
    } catch (_) {
      _horizonLoaded = true;
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  int? _parseHorizon() {
    final raw = int.tryParse(_horizonController.text.trim());
    if (raw == null || raw < 1 || raw > 52) return null;
    return raw;
  }

  Future<void> _submit() async {
    final studentId = _studentId;
    if (studentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите ученика')));
      return;
    }
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один день')),
      );
      return;
    }
    final horizon = _parseHorizon();
    if (horizon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Горизонт: укажите число недель от 1 до 52'),
        ),
      );
      return;
    }
    final cubit = context.read<RecurringBookingCubit>();
    final result = await cubit.create(
      studentId: studentId,
      weekdays: _weekdays.toList()..sort(),
      startMinute: _time.hour * 60 + _time.minute,
      mode: _mode,
      horizonWeeksOverride: horizon,
    );
    if (!mounted) return;
    if (result == null) {
      final conflictId = cubit.state.conflictExistingId;
      if (conflictId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cubit.state.errorMessage ?? 'Такая серия уже есть'),
          ),
        );
        context.pop();
        if (!mounted) return;
        await context.push<void>('/schedule/recurring/$conflictId');
      }
      return;
    }
    final sync = result.sync;
    final message =
        'Забронировано: ${sync.booked}. Создано слотов: ${sync.slotsCreated}. '
        'Конфликтов: ${sync.conflicts.length}.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.read<ScheduleCalendarSync>().notifyChanged();
    // Pop with result so the caller (calendar/list) can refresh, then open detail.
    // pushReplacement completed the route future too early while still on detail,
    // so the calendar under the stack often never reloaded.
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FyTopBar(title: 'Новые регулярные тренировки'),
      body: BlocConsumer<RecurringBookingCubit, RecurringBookingState>(
        listener: (context, state) {
          if (state.status == RecurringBookingStatus.failure &&
              state.errorMessage != null &&
              state.conflictExistingId == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == RecurringBookingStatus.loading &&
              state.students.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final studentId =
              _studentId ??
              (state.students.isNotEmpty
                  ? state.students.first.studentId
                  : null);
          if (_studentId == null && studentId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _studentId = studentId);
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.students.isEmpty)
                const FyInfoBanner(
                  message:
                      'Нет связанных учеников. Сначала пригласите ученика по QR.',
                )
              else ...[
                FyCard(
                  child: FySearchSelectField<String>(
                    fieldKey: const Key('recurring-student'),
                    label: 'Ученик',
                    hintText: 'Выберите ученика',
                    searchHintText: 'Имя или email',
                    sheetTitle: 'Ученик',
                    value: studentId,
                    options: studentSearchSelectOptions(state.students),
                    onChanged: (value) => setState(() => _studentId = value),
                  ),
                ),
                const SizedBox(height: 12),
                FyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дни недели',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      WeekdayMultiPicker(
                        selectedWeekdays: _weekdays,
                        onChanged: (next) => setState(() {
                          _weekdays
                            ..clear()
                            ..addAll(next);
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Время начала',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        key: const Key('recurring-time'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          formatStartMinute(_time.hour * 60 + _time.minute),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: _pickTime,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Формат',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'offline', label: Text('Очно')),
                          ButtonSegment(value: 'online', label: Text('Онлайн')),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (value) =>
                            setState(() => _mode = value.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FyInputCard(
                  key: const Key('recurring-horizon'),
                  label: 'Горизонт (недель)',
                  icon: Icons.date_range_rounded,
                  controller: _horizonController,
                  keyboardType: TextInputType.number,
                  unit: 'нед.',
                ),
                const SizedBox(height: 24),
                FyPrimaryButton(
                  key: const Key('recurring-submit'),
                  label: 'Создать серию',
                  isLoading: state.status == RecurringBookingStatus.saving,
                  onPressed: state.students.isEmpty ? null : _submit,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
