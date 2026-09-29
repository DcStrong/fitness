import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../../../core/widgets/person_name_email.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../finance/data/finance_repository.dart';
import '../../../finance/data/money_formatter.dart';
import '../../../social/data/social_repository.dart';
import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../schedule_format.dart';
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
      _sessions.where((s) => s.status == 'booked').toList(growable: false);

  List<TrainingSession> get _archive =>
      _sessions.where((s) => s.status != 'booked').toList(growable: false);

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

  Future<void> _confirmCancel(TrainingSession session) async {
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить тренировку?'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Комментарий (необязательно)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (ok != true || !mounted) return;
    await _runAction(
      session.id,
      () => context.read<ScheduleRepository>().cancelSession(
        session.id,
        note: note.isEmpty ? null : note,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Тренировка отменена, время снова свободно'),
      ),
    );
  }

  Future<void> _confirmNoShow(TrainingSession session) async {
    final charge = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Отметить неявку'),
        content: const Text('Списать стоимость тренировки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет, без оплаты'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, начислить'),
          ),
        ],
      ),
    );
    if (charge == null || !mounted) return;
    await _runAction(
      session.id,
      () => context.read<ScheduleRepository>().markNoShow(
        session.id,
        charge: charge,
      ),
    );
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

    return Scaffold(
      appBar: FyTopBar(
        title: 'Журнал тренировок',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(isTrainer ? '/schedule' : '/home');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(key: Key('sessions-tab-upcoming'), text: 'Предстоящие'),
            Tab(key: Key('sessions-tab-archive'), text: 'Архив'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? const Padding(
              padding: EdgeInsets.all(24),
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
                _SessionsTabList(
                  sessions: _upcoming,
                  emptyMessage: 'Нет предстоящих тренировок.',
                  userId: user?.id,
                  permissions: user?.permissions ?? const [],
                  busyId: _busyId,
                  reviewEligibleSessionIds: _reviewEligibleSessionIds,
                  onComplete: (session) => _runAction(
                    session.id,
                    () => context.read<ScheduleRepository>().completeSession(
                      session.id,
                    ),
                  ),
                  onCancel: _confirmCancel,
                  onNoShow: _confirmNoShow,
                  onMarkPaid: _markPaid,
                  onHistory: (session) =>
                      context.push('/sessions/${session.id}/history'),
                  onReview: (session) => context
                      .push<bool>('/reviews/new?sessionId=${session.id}')
                      .then((saved) {
                        if (saved == true) _load();
                      }),
                ),
                _SessionsTabList(
                  sessions: _archive,
                  emptyMessage:
                      'Архив пуст — отменённые и завершённые появятся здесь.',
                  userId: user?.id,
                  permissions: user?.permissions ?? const [],
                  busyId: _busyId,
                  reviewEligibleSessionIds: _reviewEligibleSessionIds,
                  onComplete: (session) => _runAction(
                    session.id,
                    () => context.read<ScheduleRepository>().completeSession(
                      session.id,
                    ),
                  ),
                  onCancel: _confirmCancel,
                  onNoShow: _confirmNoShow,
                  onMarkPaid: _markPaid,
                  onHistory: (session) =>
                      context.push('/sessions/${session.id}/history'),
                  onReview: (session) => context
                      .push<bool>('/reviews/new?sessionId=${session.id}')
                      .then((saved) {
                        if (saved == true) _load();
                      }),
                ),
              ],
            ),
    );
  }
}

class _SessionsTabList extends StatelessWidget {
  const _SessionsTabList({
    required this.sessions,
    required this.emptyMessage,
    required this.userId,
    required this.permissions,
    required this.busyId,
    required this.reviewEligibleSessionIds,
    required this.onComplete,
    required this.onCancel,
    required this.onNoShow,
    required this.onMarkPaid,
    required this.onHistory,
    required this.onReview,
  });

  final List<TrainingSession> sessions;
  final String emptyMessage;
  final String? userId;
  final List<String> permissions;
  final String? busyId;
  final Set<String> reviewEligibleSessionIds;
  final void Function(TrainingSession session) onComplete;
  final void Function(TrainingSession session) onCancel;
  final void Function(TrainingSession session) onNoShow;
  final void Function(TrainingSession session) onMarkPaid;
  final void Function(TrainingSession session) onHistory;
  final void Function(TrainingSession session) onReview;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: FyCard(
          child: FyInfoBanner(
            message: emptyMessage,
            icon: Icons.event_note_outlined,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(
          session: session,
          userId: userId,
          permissions: permissions,
          busy: busyId == session.id,
          onComplete: () => onComplete(session),
          onCancel: () => onCancel(session),
          onNoShow: () => onNoShow(session),
          onMarkPaid: () => onMarkPaid(session),
          onHistory: () => onHistory(session),
          canReview: reviewEligibleSessionIds.contains(session.id),
          onReview: () => onReview(session),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.userId,
    required this.permissions,
    required this.busy,
    required this.onComplete,
    required this.onCancel,
    required this.onNoShow,
    required this.onMarkPaid,
    required this.onHistory,
    required this.canReview,
    required this.onReview,
  });

  final TrainingSession session;
  final String? userId;
  final List<String> permissions;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onNoShow;
  final VoidCallback onMarkPaid;
  final VoidCallback onHistory;
  final bool canReview;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(session.startsAt);
    final end = DateTime.parse(session.endsAt);
    final viewerId = userId;
    final isCoach = viewerId != null && viewerId == session.coachId;
    final peerName = viewerId == null
        ? personPrimaryLabel(
            displayName: session.studentDisplayName ?? session.coachDisplayName,
            email: session.studentEmail ?? session.coachEmail,
          )
        : session.peerPrimaryLabel(viewerId);
    final peerEmail = viewerId == null
        ? personEmailCaption(
            displayName: session.studentDisplayName ?? session.coachDisplayName,
            email: session.studentEmail ?? session.coachEmail,
          )
        : session.peerEmailCaption(viewerId);
    final isParticipant =
        viewerId != null &&
        (viewerId == session.coachId || viewerId == session.studentId);
    final booked = session.status == 'booked';

    final canComplete =
        booked && isCoach && permissions.contains('sessions:complete');
    final canNoShow =
        booked && isCoach && permissions.contains('sessions:mark_no_show');
    final canCancel =
        booked && isParticipant && permissions.contains('sessions:cancel');
    final canHistory =
        isParticipant && permissions.contains('sessions:read_history');
    final canMarkPaid =
        isCoach &&
        session.finance.canMarkPaid &&
        permissions.contains('finance:mark_paid');

    return FyCard(
      onTap: () => context.push('/sessions/${session.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.self_improvement_rounded,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sessionStatusLabel(session.status),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (peerEmail != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        peerEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _financeLabel(session),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          if (busy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ] else ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canComplete)
                  FilledButton(
                    onPressed: onComplete,
                    child: const Text('Провести'),
                  ),
                if (canNoShow)
                  OutlinedButton(
                    onPressed: onNoShow,
                    child: const Text('Неявка'),
                  ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Отменить'),
                  ),
                if (canMarkPaid)
                  FilledButton.tonal(
                    onPressed: onMarkPaid,
                    child: const Text('Оплачено'),
                  ),
                if (canHistory)
                  TextButton(
                    onPressed: onHistory,
                    child: const Text('История'),
                  ),
                if (canReview)
                  FilledButton.tonal(
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

  String _financeLabel(TrainingSession session) {
    final finance = session.finance;
    if (!finance.isTracked) return 'Финансы: не учитывается';
    final amount = MoneyFormatter.format(
      finance.amountMinor!,
      currency: finance.currency ?? 'RUB',
    );
    final status = switch (finance.status) {
      'paid' => 'оплачено',
      'cancelled' => 'отменено',
      'pending' when finance.earnedAt != null => 'ожидает оплаты',
      'pending' => 'оплата после тренировки',
      _ => finance.status,
    };
    return '$amount · $status';
  }
}
