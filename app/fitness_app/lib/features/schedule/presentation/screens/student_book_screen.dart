import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_avatar.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_square_icon_button.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../../booking_requests/presentation/cubit/student_requests_cubit.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../home/presentation/home_format.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_range.dart';
import '../booking_format.dart';
import '../schedule_format.dart';

class StudentBookScreen extends StatelessWidget {
  const StudentBookScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => StudentRequestsCubit(
      repository: context.read<BookingRequestsRepository>(),
    ),
    child: const _StudentBookView(),
  );
}

class _StudentBookView extends StatefulWidget {
  const _StudentBookView();

  @override
  State<_StudentBookView> createState() => _StudentBookViewState();
}

class _StudentBookViewState extends State<_StudentBookView> {
  List<RelationshipItem> _coaches = const [];
  String? _selectedCoachId;
  List<ScheduleSlot> _slots = const [];
  bool _loadingRels = true;
  bool _loadingSlots = false;
  String? _error;
  String? _bookingId;
  DateTime? _selectedDay;
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _loadRelationships();
  }

  Future<void> _loadRelationships() async {
    setState(() {
      _loadingRels = true;
      _error = null;
    });
    try {
      final items = await context
          .read<InvitationsRepository>()
          .listRelationships();
      final coaches = items.where((r) => r.roleForViewer == 'student').toList();
      if (!mounted) return;
      setState(() {
        _coaches = coaches;
        _selectedCoachId = coaches.isNotEmpty ? coaches.first.coachId : null;
        _loadingRels = false;
      });
      if (_selectedCoachId != null) {
        await _loadSlots();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingRels = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    final coachId = _selectedCoachId;
    if (coachId == null) return;
    setState(() {
      _loadingSlots = true;
      _error = null;
    });
    try {
      final slots = await context.read<ScheduleRepository>().listCoachOpenSlots(
        coachId,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
        final days = _slotDays(slots);
        if (_selectedDay == null || !days.contains(_selectedDay)) {
          _selectedDay = days.isEmpty ? null : days.first;
        }
        if (!slots.any((slot) => slot.id == _selectedSlotId)) {
          _selectedSlotId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingSlots = false;
      });
    }
  }

  Future<void> _book(ScheduleSlot slot) async {
    setState(() => _bookingId = slot.id);
    try {
      final created = await context.read<StudentRequestsCubit>().create(
        slot.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created
                ? 'Заявка отправлена. Ожидайте подтверждения тренера.'
                : context.read<StudentRequestsCubit>().state.message ??
                      'Не удалось отправить заявку',
          ),
        ),
      );
      if (created) setState(() => _selectedSlotId = null);
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _bookingId = null);
    }
  }

  ScheduleSlot? get _selectedSlot {
    for (final slot in _slots) {
      if (slot.id == _selectedSlotId) return slot;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedSlot;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadRelationships,
          child: _buildBody(context),
        ),
      ),
      bottomNavigationBar: selected == null
          ? null
          : _BookingSummaryBar(
              slot: selected,
              busy: _bookingId == selected.id,
              onSubmit: () => _book(selected),
            ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Запись',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        FySquareIconButton(
          buttonKey: const Key('book-my-requests'),
          tooltip: 'Мои заявки',
          icon: Icons.event_note_outlined,
          onPressed: () => context.push('/booking-requests/mine'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 24);
    if (_loadingRels) {
      return ListView(
        padding: padding,
        children: [
          _header(context),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_coaches.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          _header(context),
          const SizedBox(height: 16),
          const FyCard(
            child: FyInfoBanner(
              message: 'Сначала примите приглашение от тренера.',
              icon: Icons.person_add_alt_1_outlined,
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = _stripDays(_slots, now);
    final slotDays = _slotDays(_slots).toSet();
    final selectedDay = _selectedDay;
    final daySlots = [
      for (final slot in _slots)
        if (selectedDay != null &&
            isSameCalendarDay(
              DateTime.parse(slot.startsAt).toLocal(),
              selectedDay,
            ))
          slot,
    ];

    return ListView(
      padding: padding,
      children: [
        _header(context),
        const SizedBox(height: 16),
        for (final coach in _coaches)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CoachCard(
              coach: coach,
              selected: coach.coachId == _selectedCoachId,
              selectable: _coaches.length > 1,
              priceCaption: _priceCaption(),
              onTap: () async {
                setState(() {
                  _selectedCoachId = coach.coachId;
                  _selectedDay = null;
                  _selectedSlotId = null;
                });
                await _loadSlots();
              },
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          const FyInfoBanner(
            message:
                'Не удалось загрузить расписание. Потяните вниз, чтобы обновить.',
            icon: Icons.sync_problem_rounded,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                formatBookingMonth(selectedDay ?? now),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'точка — есть свободное время',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DayStrip(
          days: days,
          slotDays: slotDays,
          selected: selectedDay,
          onSelected: (day) => setState(() {
            _selectedDay = day;
            _selectedSlotId = null;
          }),
        ),
        const SizedBox(height: 20),
        if (_loadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_slots.isEmpty)
          const FyCard(
            child: FyInfoBanner(
              message:
                  'Нет слотов, на которые ещё можно подать заявку. Запись закрывается за 2 часа до начала.',
              icon: Icons.event_busy_outlined,
            ),
          )
        else ...[
          Text(
            selectedDay == null
                ? 'Выберите день'
                : formatBookingDayTitle(selectedDay, now: now),
            key: const Key('book-day-title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (daySlots.isEmpty)
            Text(
              'В этот день свободного времени нет — выберите день с точкой.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            _SlotGrid(
              slots: daySlots,
              selectedId: _selectedSlotId,
              onSelected: (slot) => setState(() => _selectedSlotId = slot.id),
            ),
          const SizedBox(height: 16),
          const _BookingHint(),
        ],
      ],
    );
  }

  /// Price of the coach's slots, when all of them cost the same.
  String _priceCaption() {
    final prices = {
      for (final slot in _slots)
        if (slot.price case final price?)
          MoneyFormatter.format(price.amountMinor, currency: price.currency),
    };
    if (prices.length == 1) return 'Разовое ${prices.first}';
    return 'Ваш тренер';
  }
}

/// Local calendar days that have at least one slot, in order.
List<DateTime> _slotDays(List<ScheduleSlot> slots) {
  final days = <DateTime>{
    for (final slot in slots)
      calendarDateOnly(DateTime.parse(slot.startsAt).toLocal()),
  }.toList()..sort();
  return days;
}

/// Today through the last day with a slot, at least one week.
List<DateTime> _stripDays(List<ScheduleSlot> slots, DateTime now) {
  final today = calendarDateOnly(now);
  final slotDays = _slotDays(slots);
  var last = DateTime(today.year, today.month, today.day + 6);
  if (slotDays.isNotEmpty && slotDays.last.isAfter(last)) last = slotDays.last;
  final first = slotDays.isNotEmpty && slotDays.first.isBefore(today)
      ? slotDays.first
      : today;
  return [
    for (
      var day = first;
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1)
    )
      day,
  ];
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.coach,
    required this.selected,
    required this.selectable,
    required this.priceCaption,
    required this.onTap,
  });

  final RelationshipItem coach;
  final bool selected;
  final bool selectable;
  final String priceCaption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = selectable && selected;
    return Material(
      color: highlighted ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: highlighted ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        key: Key('book-coach-${coach.coachId}'),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        onTap: selectable && !selected ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              FyAvatar(
                displayName: coach.coachDisplayName,
                email: coach.coachEmail,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.coachLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected)
                      Text(priceCaption, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selectable)
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.borderStrong,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.slotDays,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> days;
  final Set<DateTime> slotDays;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Seven days fill the width; longer ranges scroll sideways.
        final itemWidth = (constraints.maxWidth - 6 * 4) / 7;
        return SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final day = days[index];
              return SizedBox(
                width: itemWidth,
                child: _DayButton(
                  day: day,
                  hasSlots: slotDays.contains(day),
                  selected: selected == day,
                  onTap: () => onSelected(day),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.hasSlots,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool hasSlots;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekdayColor = selected
        ? AppColors.onPrimaryMuted
        : AppColors.textSecondary;
    final dayColor = selected
        ? AppColors.onPrimary
        : hasSlots
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final dotColor = selected
        ? AppColors.mint
        : hasSlots
        ? AppColors.primary
        : Colors.transparent;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: InkWell(
          key: Key('book-day-${day.year}-${day.month}-${day.day}'),
          borderRadius: BorderRadius.circular(AppRadii.control),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatHomeWeekdayShort(day),
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: weekdayColor,
                ),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: dayColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ScheduleSlot> slots;
  final String? selectedId;
  final ValueChanged<ScheduleSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        for (final slot in slots)
          _SlotTile(
            slot: slot,
            selected: slot.id == selectedId,
            onTap: () => onSelected(slot),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ScheduleSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final online = slot.mode == 'online';
    final unavailable = slot.held || slot.price == null;
    final foreground = unavailable
        ? AppColors.textSecondary
        : selected
        ? AppColors.primary
        : AppColors.textPrimary;
    final caption = slot.held
        ? 'Занято'
        : slot.price == null
        ? 'Нет цены'
        : online
        ? 'Онлайн'
        : 'Офлайн';
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.primarySoft
            : unavailable
            ? AppColors.sunken
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          key: Key('book-slot-${slot.id}'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          onTap: unavailable ? null : onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTime(DateTime.parse(slot.startsAt)),
                style: TextStyle(
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!unavailable) ...[
                    Icon(
                      online ? Icons.videocam_outlined : Icons.place_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingHint extends StatelessWidget {
  const _BookingHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Время держится за вами, пока тренер не ответит. '
                'Запись закрывается за 2 часа до начала.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selected slot and the one filled action of the screen.
class _BookingSummaryBar extends StatelessWidget {
  const _BookingSummaryBar({
    required this.slot,
    required this.busy,
    required this.onSubmit,
  });

  final ScheduleSlot slot;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = slot.price;
    final online = slot.mode == 'online';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: FyCard(
          key: const Key('book-summary'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatBookingSummary(DateTime.parse(slot.startsAt)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      [
                        online ? 'Онлайн' : 'Офлайн',
                        if (price != null)
                          MoneyFormatter.format(
                            price.amountMinor,
                            currency: price.currency,
                          ),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('book-submit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: busy ? null : onSubmit,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Отправить заявку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
