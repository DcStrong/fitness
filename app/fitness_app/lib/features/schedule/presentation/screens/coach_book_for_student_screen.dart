import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_search_select_field.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../../finance/data/money_formatter.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../schedule_calendar_sync.dart';
import '../schedule_format.dart';
import '../widgets/student_search_select.dart';
import '../../../../core/widgets/fy_top_bar.dart';

/// Prefill for coach one-off booking (slot XOR time range).
class CoachBookPrefill {
  const CoachBookPrefill({
    this.slotId,
    this.startsAt,
    this.endsAt,
    this.mode,
    this.studentId,
  });

  final String? slotId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? mode;
  final String? studentId;

  bool get hasSlot => slotId != null;
  bool get hasTimeRange => startsAt != null && endsAt != null;
}

/// Coach books a linked student on an open slot or at an arbitrary time.
class CoachBookForStudentScreen extends StatefulWidget {
  const CoachBookForStudentScreen({this.prefill, super.key});

  final CoachBookPrefill? prefill;

  @override
  State<CoachBookForStudentScreen> createState() =>
      _CoachBookForStudentScreenState();
}

class _CoachBookForStudentScreenState extends State<CoachBookForStudentScreen> {
  List<RelationshipItem> _students = const [];
  String? _selectedStudentId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late String _mode;
  bool _timeEditable = true;

  CoachBookPrefill get _prefill => widget.prefill ?? const CoachBookPrefill();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    final rounded = DateTime(now.year, now.month, now.day, now.hour);
    if (_prefill.hasTimeRange) {
      _startsAt = _prefill.startsAt!;
      _endsAt = _prefill.endsAt!;
      _mode = _prefill.mode ?? 'offline';
      _timeEditable = !_prefill.hasSlot;
    } else if (_prefill.hasSlot) {
      // Slot times loaded after we optionally fetch; until then placeholders.
      _startsAt = rounded;
      _endsAt = rounded.add(const Duration(hours: 1));
      _mode = _prefill.mode ?? 'offline';
      _timeEditable = false;
    } else {
      _startsAt = rounded;
      _endsAt = rounded.add(const Duration(hours: 1));
      _mode = 'offline';
      _timeEditable = true;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<InvitationsRepository>();
      final schedule = context.read<ScheduleRepository>();
      final rels = await repo.listRelationships();
      final students = rels.where((r) => r.roleForViewer == 'coach').toList();

      if (_prefill.hasSlot && _prefill.slotId != null) {
        final slots = await schedule.listOwnSlots();
        ScheduleSlot? slot;
        for (final candidate in slots) {
          if (candidate.id == _prefill.slotId) {
            slot = candidate;
            break;
          }
        }
        if (slot != null) {
          _startsAt = DateTime.parse(slot.startsAt).toLocal();
          _endsAt = DateTime.parse(slot.endsAt).toLocal();
          _mode = slot.mode;
        }
      } else if (!_prefill.hasTimeRange) {
        try {
          final settings = await schedule.getAvailabilitySettings();
          final duration = settings.defaultDurationMinutes;
          _endsAt = _startsAt.add(Duration(minutes: duration));
        } catch (_) {
          // Keep 60m default.
        }
      }

      if (!mounted) return;
      setState(() {
        _students = students;
        final prefillId = _prefill.studentId;
        _selectedStudentId = students.any((item) => item.studentId == prefillId)
            ? prefillId
            : (students.isNotEmpty ? students.first.studentId : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    if (!_timeEditable) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    final duration = _endsAt.difference(_startsAt);
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _startsAt = next;
      _endsAt = next.add(
        duration.isNegative ? const Duration(hours: 1) : duration,
      );
    });
  }

  Future<void> _choosePriceAndBook() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    if (!_endsAt.isAfter(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Окончание должно быть позже начала')),
      );
      return;
    }

    final result = await showDialog<(bool, String?)>(
      context: context,
      builder: (dialogContext) => const _SessionPriceDialog(),
    );
    if (result?.$1 == true && mounted) {
      await _book(priceMinor: result?.$2);
    }
  }

  Future<void> _book({String? priceMinor}) async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;
    setState(() => _submitting = true);
    try {
      final schedule = context.read<ScheduleRepository>();
      if (_prefill.hasSlot && _prefill.slotId != null) {
        await schedule.book(
          scheduleSlotId: _prefill.slotId!,
          studentId: studentId,
          priceMinor: priceMinor,
        );
      } else {
        await schedule.bookAtTime(
          startsAt: _startsAt,
          endsAt: _endsAt,
          studentId: studentId,
          mode: _mode,
          priceMinor: priceMinor,
        );
      }
      if (!mounted) return;
      context.read<ScheduleCalendarSync>().notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ученик записан')));
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/schedule');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _modeLabel(String mode) => mode == 'online' ? 'онлайн' : 'очно';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Записать ученика',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/schedule');
            }
          },
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: FyCard(
          child: FyInfoBanner(
            message: 'Не удалось загрузить данные для записи.',
            icon: Icons.sync_problem_rounded,
          ),
        ),
      );
    }
    if (_students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: FyCard(
          child: FyInfoBanner(
            message: 'Нет связанных учеников. Сначала отправьте приглашение.',
            icon: Icons.people_outline_rounded,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          'Запись ученика',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _prefill.hasSlot
              ? 'Выберите ученика и подтвердите запись на свободный слот.'
              : 'Выберите ученика и время. Слот создастся автоматически.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        FyCard(
          child: FySearchSelectField<String>(
            fieldKey: const Key('book-student-select'),
            label: 'Ученик',
            hintText: 'Выберите ученика',
            searchHintText: 'Имя или email',
            sheetTitle: 'Ученик',
            value: _selectedStudentId,
            options: studentSearchSelectOptions(_students),
            onChanged: (value) => setState(() => _selectedStudentId = value),
          ),
        ),
        const SizedBox(height: 16),
        FyCard(
          onTap: _timeEditable ? _pickStart : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Время',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatDateTime(_startsAt)} – ${formatTime(_endsAt)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _modeLabel(_mode),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              if (_timeEditable) ...[
                const SizedBox(height: 12),
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        FyPrimaryButton(
          key: const Key('coach-book-submit'),
          label: 'Записать',
          onPressed: _submitting || _selectedStudentId == null
              ? null
              : _choosePriceAndBook,
          isLoading: _submitting,
          showTrailingArrow: true,
        ),
      ],
    );
  }
}

/// Owns [TextEditingController] for the session price dialog lifecycle.
class _SessionPriceDialog extends StatefulWidget {
  const _SessionPriceDialog();

  @override
  State<_SessionPriceDialog> createState() => _SessionPriceDialogState();
}

class _SessionPriceDialogState extends State<_SessionPriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    final price = text.isEmpty ? null : MoneyFormatter.parseRubles(text);
    if (text.isEmpty || price != null) {
      Navigator.pop(context, (true, price));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Цена этой тренировки'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Своя цена, ₽',
          hintText: 'Оставьте пустым для базовой цены',
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Записать')),
      ],
    );
  }
}
