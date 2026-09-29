import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_date_picker.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../schedule_format.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class CoachSlotsScreen extends StatefulWidget {
  const CoachSlotsScreen({super.key});

  @override
  State<CoachSlotsScreen> createState() => _CoachSlotsScreenState();
}

class _CoachSlotsScreenState extends State<CoachSlotsScreen> {
  List<ScheduleSlot> _slots = const [];
  bool _loading = true;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slots = await context.read<ScheduleRepository>().listOwnSlots();
      if (!mounted) return;
      setState(() {
        _slots = slots;
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

  Future<void> _createSlot() async {
    final now = DateTime.now().add(const Duration(hours: 1));
    final date = await showFyDatePicker(
      context: context,
      title: 'Дата слота',
      initialDate: now,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final endsAt = startsAt.add(const Duration(hours: 1));

    setState(() => _creating = true);
    try {
      await context.read<ScheduleRepository>().createSlot(
        startsAt: startsAt,
        endsAt: endsAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Свободное время добавлено')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _delete(ScheduleSlot slot) async {
    try {
      await context.read<ScheduleRepository>().deleteSlot(slot.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Слот удалён')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Доступность',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          'Планируйте свободное время',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Добавляйте слоты — ученики увидят доступное время для записи.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        FyPrimaryButton(
          label: 'Добавить свободное время',
          onPressed: _creating ? null : _createSlot,
          isLoading: _creating,
          showTrailingArrow: true,
        ),
        const SizedBox(height: 20),
        if (_error != null)
          const FyCard(
            child: FyInfoBanner(
              message: 'Не удалось загрузить слоты. Попробуйте обновить.',
              icon: Icons.sync_problem_rounded,
            ),
          )
        else if (_slots.isEmpty)
          const FyCard(
            child: FyInfoBanner(
              message: 'Слотов пока нет. Добавьте первое свободное время.',
              icon: Icons.event_available_outlined,
            ),
          )
        else
          ..._slots.map((slot) {
            final start = DateTime.parse(slot.startsAt);
            final end = DateTime.parse(slot.endsAt);
            final open = slot.status == 'open';
            final modeLabel = slot.mode == 'online' ? 'онлайн' : 'очно';
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FyCard(
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatDateTime(start)} – ${formatTime(end)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$modeLabel · ${open ? 'открыт' : slot.status}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (open)
                      IconButton(
                        tooltip: 'Удалить слот',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _delete(slot),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
