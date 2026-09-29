import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../finance/data/money_formatter.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../data/booking_request_models.dart';
import '../data/booking_requests_repository.dart';
import 'cubit/student_requests_cubit.dart';
import '../../../core/widgets/fy_top_bar.dart';

class StudentRequestsPage extends StatelessWidget {
  const StudentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => StudentRequestsCubit(
      repository: context.read<BookingRequestsRepository>(),
    )..load(),
    child: const StudentRequestsView(),
  );
}

class StudentRequestsView extends StatelessWidget {
  const StudentRequestsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const FyTopBar(title: 'Мои заявки'),
    body: BlocConsumer<StudentRequestsCubit, StudentRequestsState>(
      listenWhen: (previous, current) =>
          current.message != null && current.message != previous.message,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) {
        if (state.status == StudentRequestsStatus.loading ||
            state.status == StudentRequestsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == StudentRequestsStatus.failure &&
            state.items.isEmpty) {
          return _Failure(onRetry: context.read<StudentRequestsCubit>().load);
        }
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: context.read<StudentRequestsCubit>().refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                FyCard(
                  child: FyInfoBanner(
                    message: 'У вас пока нет заявок на тренировку.',
                    icon: Icons.event_note_outlined,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<StudentRequestsCubit>().refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _RequestCard(
              request: state.items[index],
              submitting: state.status == StudentRequestsStatus.submitting,
            ),
          ),
        );
      },
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.submitting});

  final BookingRequest request;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final slot = request.displayedSlot;
    return FyCard(
      onTap: () =>
          context.push('/booking-requests/${request.id}', extra: request),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                request.counterpart.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Chip(label: Text(_statusLabel(request.status))),
            ],
          ),
          Text(
            '${formatDateTime(slot.startsAt.toLocal())} – '
            '${formatTime(slot.endsAt.toLocal())}',
          ),
          const SizedBox(height: 4),
          Text(
            '${slot.mode == 'online' ? 'Онлайн' : 'Очно'} · '
            '${MoneyFormatter.format(request.quotedPriceMinor, currency: request.quotedCurrency)}',
          ),
          if (request.isPending) ...[
            const SizedBox(height: 6),
            Text('Ответ до ${formatDateTime(request.expiresAt.toLocal())}'),
          ],
          if (request.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Причина: ${_reasonLabel(request.rejectionReason!)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (request.rejectionComment?.isNotEmpty == true)
              Text(request.rejectionComment!),
          ],
          if (request.resolution == BookingRequestResolution.alternateSlot)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Тренер назначил согласованное другое время.'),
            ),
          if (request.sessionId != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go('/sessions'),
              child: const Text('Открыть тренировку'),
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: submitting ? null : () => _withdraw(context),
              child: const Text('Отозвать заявку'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отозвать заявку?'),
        content: const Text('Слот снова станет доступен другим ученикам.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Оставить'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<StudentRequestsCubit>().withdraw(request.id);
    }
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: FyCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FyInfoBanner(
              message: 'Не удалось загрузить заявки.',
              icon: Icons.sync_problem_rounded,
            ),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    ),
  );
}

String _statusLabel(BookingRequestStatus status) => switch (status) {
  BookingRequestStatus.pending => 'Ожидает тренера',
  BookingRequestStatus.accepted => 'Принята',
  BookingRequestStatus.rejected => 'Отклонена',
  BookingRequestStatus.withdrawn => 'Отозвана',
  BookingRequestStatus.expired => 'Истекла',
};

String _reasonLabel(BookingRequestRejectionReason reason) => switch (reason) {
  BookingRequestRejectionReason.timeUnavailable => 'Время недоступно',
  BookingRequestRejectionReason.plansChanged => 'Планы изменились',
  BookingRequestRejectionReason.other => 'Другое',
};
