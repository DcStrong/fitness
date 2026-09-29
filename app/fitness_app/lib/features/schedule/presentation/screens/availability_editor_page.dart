import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_date_picker.dart';
import '../../../../core/widgets/fy_field_help.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_input_card.dart';
import '../../data/availability_models.dart';
import '../../data/schedule_repository.dart';
import '../cubit/availability_editor_cubit.dart';
import '../schedule_format.dart';
import '../widgets/day_of_week_picker.dart';

const _helpDuration =
    'Сколько минут длится одна тренировка. По этой длительности '
    'режется рабочее окно при генерации свободных слотов.';
const _helpBreak =
    'Пауза между соседними слотами внутри рабочего окна. '
    'Например, 15 минут — после каждого слота генератор оставляет перерыв.';
const _helpHorizon =
    'На сколько недель вперёд создавать свободные слоты из шаблона '
    'рабочей недели. Например, 8 — слоты появятся примерно на два месяца.';
const _helpWindows =
    'Рабочие часы выбранного дня недели. Именно из этих окон '
    'генерируются свободные слоты в календаре.';
const _helpExceptions =
    'Дни-исключения: выходные или особые часы, которые перекрывают '
    'обычный шаблон недели при генерации.';

class AvailabilityEditorPage extends StatelessWidget {
  const AvailabilityEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AvailabilityEditorCubit(
        scheduleRepository: context.read<ScheduleRepository>(),
      )..load(),
      child: const AvailabilityEditorView(),
    );
  }
}

class AvailabilityEditorView extends StatefulWidget {
  const AvailabilityEditorView({super.key});

  @override
  State<AvailabilityEditorView> createState() => _AvailabilityEditorViewState();
}

class _AvailabilityEditorViewState extends State<AvailabilityEditorView> {
  late final TextEditingController _durationController;
  late final TextEditingController _breakController;
  late final TextEditingController _horizonController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '60');
    _breakController = TextEditingController(text: '0');
    _horizonController = TextEditingController(text: '8');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _breakController.dispose();
    _horizonController.dispose();
    super.dispose();
  }

  void _syncControllers(CoachScheduleSettings settings) {
    final duration = '${settings.defaultDurationMinutes}';
    final breakMinutes = '${settings.breakMinutes}';
    final horizon = '${settings.horizonWeeks}';
    if (_durationController.text != duration) {
      _durationController.text = duration;
    }
    if (_breakController.text != breakMinutes) {
      _breakController.text = breakMinutes;
    }
    if (_horizonController.text != horizon) {
      _horizonController.text = horizon;
    }
  }

  Future<void> _addWindow(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 4) % 24, minute: start.minute),
    );
    if (end == null || !context.mounted) return;
    final startMinute = start.hour * 60 + start.minute;
    final endMinute = end.hour * 60 + end.minute;
    if (endMinute <= startMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Окончание должно быть позже начала')),
      );
      return;
    }
    context.read<AvailabilityEditorCubit>().addWindow(
      startMinute: startMinute,
      endMinute: endMinute,
    );
  }

  Future<void> _addException(BuildContext context) async {
    final now = DateTime.now();
    final date = await showFyDatePicker(
      context: context,
      title: 'День-исключение',
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final localDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.read<AvailabilityEditorCubit>().addClosedException(localDate);
  }

  void _copyToAllDays(BuildContext context) {
    context.read<AvailabilityEditorCubit>().copySelectedDayToAllDays();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Скопировано на каждый день')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AvailabilityEditorCubit, AvailabilityEditorState>(
      listenWhen: (previous, current) =>
          previous.settings != current.settings &&
          (current.status == AvailabilityEditorStatus.ready ||
              current.status == AvailabilityEditorStatus.failure),
      listener: (context, state) => _syncControllers(state.settings),
      builder: (context, state) {
        if (state.status == AvailabilityEditorStatus.loading ||
            state.status == AvailabilityEditorStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AvailabilityEditorStatus.failure &&
            state.windows.isEmpty &&
            state.seriesId.isEmpty) {
          return _ErrorBody(
            message: state.errorMessage ?? 'Не удалось загрузить',
            onRetry: () => context.read<AvailabilityEditorCubit>().load(),
          );
        }

        final dayWindows = state.windowsForSelectedDay();
        final saving = state.status == AvailabilityEditorStatus.saving;
        final generating = state.status == AvailabilityEditorStatus.generating;

        return ListView(
          key: const Key('availability-editor-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (state.errorMessage != null) ...[
              FyInfoBanner(
                message: state.errorMessage!,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: 12),
            ],
            if (state.lastGenerateSummary != null) ...[
              FyInfoBanner(
                message:
                    'Создано: ${state.lastGenerateSummary!.created}, пропущено: ${state.lastGenerateSummary!.skippedExisting + state.lastGenerateSummary!.skippedConflict}, удалено устаревших: ${state.lastGenerateSummary!.removedOrphanOpen}',
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Настройки графика',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            FyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FyFieldHelpLabel(
                    text: 'Длительность тренировки',
                    helpTitle: 'Длительность тренировки',
                    helpBody: _helpDuration,
                  ),
                  const SizedBox(height: 6),
                  FyInputCard(
                    label: 'Например, 60',
                    icon: Icons.timer_outlined,
                    unit: 'мин',
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        context.read<AvailabilityEditorCubit>().updateDuration(
                          parsed,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const FyFieldHelpLabel(
                    text: 'Перерыв между тренировками',
                    helpTitle: 'Перерыв между тренировками',
                    helpBody: _helpBreak,
                  ),
                  const SizedBox(height: 6),
                  FyInputCard(
                    label: 'Например, 15',
                    icon: Icons.coffee_outlined,
                    unit: 'мин',
                    controller: _breakController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        context.read<AvailabilityEditorCubit>().updateBreak(
                          parsed,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const FyFieldHelpLabel(
                    text: 'Горизонт генерации',
                    helpTitle: 'Горизонт генерации',
                    helpBody: _helpHorizon,
                  ),
                  const SizedBox(height: 6),
                  FyInputCard(
                    label: 'Например, 8',
                    icon: Icons.calendar_view_month_outlined,
                    unit: 'нед',
                    controller: _horizonController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        context.read<AvailabilityEditorCubit>().updateHorizon(
                          parsed,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const FyFieldHelpLabel(
              text: 'Рабочая неделя',
              helpTitle: 'Рабочая неделя',
              helpBody: _helpWindows,
            ),
            const SizedBox(height: 10),
            DayOfWeekPicker(
              selectedDayOfWeek: state.selectedDayOfWeek,
              onSelected: context.read<AvailabilityEditorCubit>().selectDay,
            ),
            const SizedBox(height: 12),
            if (dayWindows.isEmpty)
              const FyInfoBanner(
                message: 'Нет окон на этот день. Добавьте рабочие часы.',
              ),
            for (final window in dayWindows) ...[
              FyCard(
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatMinute(window.startMinute)} – ${_formatMinute(window.endMinute)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      key: Key(
                        'availability-remove-window-${window.startMinute}-${window.endMinute}',
                      ),
                      onPressed: () => context
                          .read<AvailabilityEditorCubit>()
                          .removeWindow(window),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            FyButton.soft(
              key: const Key('availability-add-hours'),
              label: '+ Добавить часы',
              onPressed: saving || generating
                  ? null
                  : () => _addWindow(context),
              size: FyButtonSize.medium,
            ),
            const SizedBox(height: 8),
            FyButton.secondary(
              key: const Key('availability-copy-weekdays'),
              label: 'Скопировать на каждый день',
              onPressed: saving || generating
                  ? null
                  : () => _copyToAllDays(context),
              size: FyButtonSize.medium,
            ),
            const SizedBox(height: 20),
            Text(
              'Предпросмотр слотов',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (state.preview.isEmpty)
              const FyInfoBanner(
                message:
                    'Сохраните шаблон, чтобы увидеть сетку слотов, или нажмите «Сгенерировать».',
              )
            else
              FyCard(
                child: Column(
                  children: [
                    for (final slot in state.preview.take(12)) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatSlotDayRange(
                            DateTime.parse(slot.startsAt),
                            DateTime.parse(slot.endsAt),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (state.preview.length > 12)
                      Text(
                        '… и ещё ${state.preview.length - 12}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const FyFieldHelpLabel(
              text: 'Исключения',
              helpTitle: 'Исключения',
              helpBody: _helpExceptions,
            ),
            const SizedBox(height: 10),
            if (state.exceptions.isEmpty)
              const FyInfoBanner(
                message: 'Нет исключений. Можно отметить выходной день.',
              ),
            for (final item in state.exceptions) ...[
              FyCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.localDate} · ${item.type == 'closed' ? 'Выходной' : 'Особые часы'}',
                      ),
                    ),
                    IconButton(
                      onPressed: () => context
                          .read<AvailabilityEditorCubit>()
                          .removeException(item.localDate),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            FyButton.soft(
              key: const Key('availability-add-exception'),
              label: '+ Добавить выходной',
              onPressed: saving || generating
                  ? null
                  : () => _addException(context),
              size: FyButtonSize.medium,
            ),
            const SizedBox(height: 24),
            FyButton.secondary(
              key: const Key('availability-save'),
              label: 'Сохранить',
              isLoading: saving,
              onPressed: saving || generating
                  ? null
                  : () => context.read<AvailabilityEditorCubit>().saveAll(),
            ),
            const SizedBox(height: 10),
            FyButton.primary(
              key: const Key('availability-generate'),
              label: 'Сгенерировать слоты',
              isLoading: generating,
              onPressed: saving || generating
                  ? null
                  : () => context.read<AvailabilityEditorCubit>().generate(),
            ),
          ],
        );
      },
    );
  }

  String _formatMinute(int minute) {
    final hour = minute ~/ 60;
    final min = minute % 60;
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FyButton.primary(
              label: 'Повторить',
              onPressed: onRetry,
              size: FyButtonSize.medium,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
