import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../../booking_requests/presentation/cubit/student_requests_cubit.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../schedule_format.dart';
import '../../../../core/widgets/fy_top_bar.dart';

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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => StudentBookingReviewSheet(
        slot: slot,
        onSubmit: () => Navigator.pop(sheetContext, true),
      ),
    );
    if (confirmed != true || !mounted) return;
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

  String _modeLabel(String mode) => mode == 'online' ? 'онлайн' : 'очно';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Запись к тренеру',
        actions: [
          IconButton(
            key: const Key('book-my-requests'),
            tooltip: 'Мои заявки',
            onPressed: () => context.push('/booking-requests/mine'),
            icon: const Icon(Icons.event_note_outlined),
          ),
          IconButton(
            onPressed: _loadingRels || _loadingSlots ? null : _loadSlots,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingRels) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_coaches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: const [
          FyCard(
            child: FyInfoBanner(
              message: 'Сначала примите приглашение от тренера.',
              icon: Icons.person_add_alt_1_outlined,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Text(
          'Выберите время тренировки',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Сначала выберите тренера, затем свободный слот. Заявку нужно отправить не позже чем за 2 часа до начала.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        FyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Тренер',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ..._coaches.indexed.map((entry) {
                final index = entry.$1;
                final coach = entry.$2;
                final selected = coach.coachId == _selectedCoachId;
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? AppColors.primary
                            : AppColors.mintSoft,
                        foregroundColor: selected
                            ? AppColors.onPrimary
                            : AppColors.primary,
                        child: const Icon(Icons.fitness_center_rounded),
                      ),
                      title: Text(coach.coachEmail ?? coach.coachId),
                      trailing: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? AppColors.primary
                            : AppColors.iconInactive,
                      ),
                      onTap: () async {
                        setState(() => _selectedCoachId = coach.coachId);
                        await _loadSlots();
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          const FyInfoBanner(
            message: 'Не удалось загрузить расписание. Попробуйте обновить.',
            icon: Icons.sync_problem_rounded,
          ),
        ],
        const SizedBox(height: 22),
        Text(
          'Свободные слоты',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
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
        else
          ..._slots.map((slot) {
            final start = DateTime.parse(slot.startsAt);
            final end = DateTime.parse(slot.endsAt);
            final busy = _bookingId == slot.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${formatDateTime(start)} – ${formatTime(end)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_modeLabel(slot.mode)} · ${slot.status}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.price == null
                          ? 'Цена не настроена'
                          : MoneyFormatter.format(
                              slot.price!.amountMinor,
                              currency: slot.price!.currency,
                            ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 14),
                    FyPrimaryButton(
                      label: 'Отправить заявку',
                      onPressed: busy || slot.price == null
                          ? null
                          : () => _book(slot),
                      isLoading: busy,
                      showTrailingArrow: true,
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

class StudentBookingReviewSheet extends StatelessWidget {
  const StudentBookingReviewSheet({
    required this.slot,
    required this.onSubmit,
    super.key,
  });

  final ScheduleSlot slot;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Проверьте заявку',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '${formatDateTime(DateTime.parse(slot.startsAt).toLocal())} – '
            '${formatTime(DateTime.parse(slot.endsAt).toLocal())}',
          ),
          Text(slot.mode == 'online' ? 'онлайн' : 'очно'),
          if (slot.price case final price?)
            Text(
              MoneyFormatter.format(
                price.amountMinor,
                currency: price.currency,
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Тренировка будет подтверждена только после решения тренера.',
          ),
          const SizedBox(height: 16),
          FyPrimaryButton(label: 'Отправить заявку', onPressed: onSubmit),
        ],
      ),
    ),
  );
}
