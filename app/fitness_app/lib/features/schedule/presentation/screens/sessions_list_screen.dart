import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_square_icon_button.dart';
import '../../../../core/widgets/fy_status_chip.dart';
import '../../../home/presentation/home_format.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../finance/data/finance_repository.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../social/data/social_repository.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../../domain/calendar_range.dart';
import '../schedule_format.dart';
import '../session_status.dart';
import '../widgets/session_actions_sheet.dart';

String sessionStatusLabel(String status) {
  switch (status) {
    case 'booked':
      return 'Запланирована';
    case 'completed':
      return 'Проведена';
    case 'cancelled':
      return 'Отменена';
    case 'no_show':
      return 'Неявка';
    default:
      return status;
  }
}

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen>
    with SingleTickerProviderStateMixin {
  List<TrainingSession> _sessions = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;
  Set<String> _reviewEligibleSessionIds = const {};
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<TrainingSession> get _upcoming =>
      _sessions.where((s) => s.status == 'booked').toList(growable: false)
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  List<TrainingSession> get _archive =>
      _sessions.where((s) => s.status != 'booked').toList(growable: false)
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = context.read<AuthCubit>().state.user;
      final results = await Future.wait<dynamic>([
        context.read<ScheduleRepository>().listSessions(),
        if (user?.roles.contains('student') == true)
          context.read<SocialRepository>().getEligibleReviews(),
      ]);
      final items = results.first as List<TrainingSession>;
      if (!mounted) return;
      setState(() {
        _sessions = items;
        _reviewEligibleSessionIds = results.length > 1
            ? (results[1] as List)
                  .map((item) => item.sessionId as String)
                  .toSet()
            : const {};
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

  Future<void> _runAction(
    String sessionId,
    Future<dynamic> Function() action,
  ) async {
    setState(() => _busyId = sessionId);
    try {
      final result = await action();
      if (!mounted) return;
      if (result is TrainingSession && result.packageExhausted) {
        showPackageExhaustedSnackBar(context);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _markPaid(TrainingSession session) async {
    var method = 'cash';
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Отметить оплату'),
          content: DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Способ оплаты'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Наличные')),
              DropdownMenuItem(value: 'transfer', child: Text('Перевод')),
              DropdownMenuItem(value: 'card', child: Text('Карта')),
              DropdownMenuItem(value: 'other', child: Text('Другое')),
            ],
            onChanged: (value) => setState(() => method = value ?? method),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, method),
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
    final chargeId = session.finance.chargeId;
    if (selected == null || chargeId == null || !mounted) return;
    await _runAction(
      session.id,
      () => context.read<FinanceRepository>().markPaid(
        chargeId,
        paymentMethod: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final isTrainer = user?.roles.contains('trainer') == true;
    final isStudent = user?.roles.contains('student') == true;
    final permissions = user?.permissions ?? const <String>[];

    Widget list(List<TrainingSession> sessions, {required bool upcoming}) {
      return _SessionsTabList(
        sessions: sessions,
        upcoming: upcoming,
        emptyMessage: upcoming
            ? 'Нет предстоящих тренировок.'
            : 'История пуста — проведённые и отменённые появятся здесь.',
        userId: user?.id,
        busyId: _busyId,
        header: upcoming && isStudent ? const _ProgramCard() : null,
        canMarkPaid: (session) =>
            user?.id == session.coachId &&
            session.finance.canMarkPaid &&
            permissions.contains('finance:mark_paid'),
        canReview: (session) => _reviewEligibleSessionIds.contains(session.id),
        onMarkPaid: _markPaid,
        onReview: (session) => context
            .push<bool>('/reviews/new?sessionId=${session.id}')
            .then((saved) {
              if (saved == true) _load();
            }),
        onRefresh: _load,
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  // For a student this is the «Тренировки» tab root.
                  if (isTrainer || context.canPop()) ...[
                    FySquareIconButton(
                      buttonKey: const Key('sessions-back'),
                      tooltip: 'Назад',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/schedule');
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      isTrainer ? 'Журнал тренировок' : 'Тренировки',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.only(right: 20),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.border,
                tabs: const [
                  Tab(key: Key('sessions-tab-upcoming'), text: 'Предстоящие'),
                  Tab(key: Key('sessions-tab-archive'), text: 'История'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: FyCard(
                        child: FyInfoBanner(
                          message: 'Не удалось загрузить тренировки.',
                          icon: Icons.sync_problem_rounded,
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        list(_upcoming, upcoming: true),
                        list(_archive, upcoming: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Student shortcut to the program and progress hub.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FyCard(
      key: const Key('sessions-open-hub'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => context.push('/me/training'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.sunken,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Программа и прогресс',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Планы от тренера и рост результатов',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SessionsTabList extends StatelessWidget {
  const _SessionsTabList({
    required this.sessions,
    required this.upcoming,
    required this.emptyMessage,
    required this.userId,
    required this.busyId,
    required this.canMarkPaid,
    required this.canReview,
    required this.onMarkPaid,
    required this.onReview,
    required this.onRefresh,
    this.header,
  });

  final List<TrainingSession> sessions;
  final bool upcoming;
  final String emptyMessage;
  final String? userId;
  final String? busyId;
  final Widget? header;
  final bool Function(TrainingSession session) canMarkPaid;
  final bool Function(TrainingSession session) canReview;
  final void Function(TrainingSession session) onMarkPaid;
  final void Function(TrainingSession session) onReview;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (header != null) ...[header!, const SizedBox(height: 8)],
    ];
    if (sessions.isEmpty) {
      children.add(
        FyCard(
          child: FyInfoBanner(
            message: emptyMessage,
            icon: Icons.event_note_outlined,
          ),
        ),
      );
    } else {
      String? lastSection;
      for (final session in sessions) {
        final section = upcoming
            ? sessionListSection(
                DateTime.parse(session.startsAt).toLocal(),
                DateTime.now(),
              )
            : null;
        if (section != null && section != lastSection) {
          children.add(_SectionLabel(section));
          lastSection = section;
        }
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionRow(
              session: session,
              userId: userId,
              busy: busyId == session.id,
              canMarkPaid: canMarkPaid(session),
              canReview: canReview(session),
              onMarkPaid: () => onMarkPaid(session),
              onReview: () => onReview(session),
            ),
          ),
        );
      }
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: children,
      ),
    );
  }
}

/// Upcoming list sections: «Ждут отметки» (past days, still booked),
/// «Сегодня», «На этой неделе», «Позже».
String sessionListSection(DateTime start, DateTime now) {
  final today = calendarDateOnly(now);
  final day = calendarDateOnly(start);
  if (day.isBefore(today)) return 'Ждут отметки';
  if (day == today) return 'Сегодня';
  final sunday = DateTime(
    today.year,
    today.month,
    today.day + 7 - today.weekday,
  );
  if (!day.isAfter(sunday)) return 'На этой неделе';
  return 'Позже';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.userId,
    required this.busy,
    required this.canMarkPaid,
    required this.canReview,
    required this.onMarkPaid,
    required this.onReview,
  });

  final TrainingSession session;
  final String? userId;
  final bool busy;
  final bool canMarkPaid;
  final bool canReview;
  final VoidCallback onMarkPaid;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(session.startsAt).toLocal();
    final viewerId = userId ?? '';
    final peer = session.peerPrimaryLabel(viewerId);
    final title = session.workoutTitle?.trim().isNotEmpty == true
        ? session.workoutTitle!
        : 'Тренировка';
    final mode = session.mode == 'online' ? 'онлайн' : 'офлайн';
    final overdue =
        session.status == 'booked' &&
        DateTime.parse(session.endsAt).isBefore(DateTime.now());
    final (status, statusLabel) = overdue
        ? (FyStatus.waiting, 'Нужна отметка')
        : sessionStatusChip(session.status);
    // Money is the coach's bookkeeping; the student sees the price on the card.
    final finance = viewerId == session.coachId ? _financeLabel(session) : null;

    return FyCard(
      key: Key('sessions-row-${session.id}'),
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/sessions/${session.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.sunken,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatTime(start),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '${formatHomeWeekdayShort(start)} ${start.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$peer · $mode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (finance != null)
                      Text(
                        finance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FyStatusChip(status: status, label: statusLabel),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ] else if (canMarkPaid || canReview) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canMarkPaid)
                  FilledButton.tonal(
                    key: Key('sessions-mark-paid-${session.id}'),
                    onPressed: onMarkPaid,
                    child: const Text('Оплачено'),
                  ),
                if (canReview)
                  FilledButton.tonal(
                    key: Key('sessions-review-${session.id}'),
                    onPressed: onReview,
                    child: const Text('Оставить отзыв'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Money line, only when finance is tracked for this session.
  String? _financeLabel(TrainingSession session) {
    final finance = session.finance;
    if (!finance.isTracked) return null;
    final amount = MoneyFormatter.format(
      finance.amountMinor!,
      currency: finance.currency ?? 'RUB',
    );
    final status = switch (finance.status) {
      'paid' => 'оплачено',
      'cancelled' => 'отменено',
      'pending' when finance.earnedAt != null => 'ждёт оплаты',
      'pending' => 'после занятия',
      _ => finance.status,
    };
    return '$amount · $status';
  }
}
