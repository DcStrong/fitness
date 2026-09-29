import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fy_card.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../finance/data/money_formatter.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../data/booking_request_models.dart';
import '../data/booking_requests_repository.dart';
import 'cubit/student_requests_cubit.dart';
import 'cubit/trainer_inbox_cubit.dart';
import '../../../core/widgets/fy_top_bar.dart';

class BookingRequestDetailPage extends StatelessWidget {
  const BookingRequestDetailPage({required this.request, super.key});

  final BookingRequest? request;

  @override
  Widget build(BuildContext context) {
    final item = request;
    final isTrainer =
        context.read<AuthCubit>().state.user?.roles.contains('trainer') == true;
    if (item == null) {
      return Scaffold(
        appBar: const FyTopBar(title: 'Заявка'),
        body: Center(
          child: FyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Откройте заявку из списка, чтобы увидеть актуальные данные.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => context.go(
                    isTrainer
                        ? '/booking-requests/inbox'
                        : '/booking-requests/mine',
                  ),
                  child: const Text('К списку заявок'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return isTrainer
        ? BlocProvider(
            create: (context) => TrainerInboxCubit(
              repository: context.read<BookingRequestsRepository>(),
              initialItems: [item],
            ),
            child: _BookingRequestDetailView(
              initialRequest: item,
              isTrainer: true,
            ),
          )
        : BlocProvider(
            create: (context) => StudentRequestsCubit(
              repository: context.read<BookingRequestsRepository>(),
              initialItems: [item],
            ),
            child: _BookingRequestDetailView(
              initialRequest: item,
              isTrainer: false,
            ),
          );
  }
}

class _BookingRequestDetailView extends StatelessWidget {
  const _BookingRequestDetailView({
    required this.initialRequest,
    required this.isTrainer,
  });

  final BookingRequest initialRequest;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    final request = isTrainer
        ? context.select<TrainerInboxCubit, BookingRequest>(
            (cubit) => cubit.state.items.first,
          )
        : context.select<StudentRequestsCubit, BookingRequest>(
            (cubit) => cubit.state.items.first,
          );
    final slot = request.displayedSlot;
    return Scaffold(
      appBar: const FyTopBar(title: 'Заявка'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.counterpart.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatDateTime(slot.startsAt.toLocal())} – '
                  '${formatTime(slot.endsAt.toLocal())}',
                ),
                Text(slot.mode == 'online' ? 'Онлайн' : 'Очно'),
                Text(
                  MoneyFormatter.format(
                    request.quotedPriceMinor,
                    currency: request.quotedCurrency,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_statusLabel(request.status)),
                if (request.rejectionComment?.isNotEmpty == true)
                  Text(request.rejectionComment!),
                if (request.resolution ==
                    BookingRequestResolution.alternateSlot)
                  const Text('Назначено согласованное другое время.'),
                if (!isTrainer && request.sessionId != null)
                  OutlinedButton(
                    onPressed: () => context.go('/sessions'),
                    child: const Text('Открыть тренировку'),
                  ),
              ],
            ),
          ),
          if (request.isPending && isTrainer) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<TrainerInboxCubit>().accept(request.id),
              child: const Text('Принять'),
            ),
            const Text(
              'Отклонение и другое время доступны в списке заявок.',
              textAlign: TextAlign.center,
            ),
          ],
          if (request.isPending && !isTrainer) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.read<StudentRequestsCubit>().withdraw(request.id),
              child: const Text('Отозвать заявку'),
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(BookingRequestStatus status) => switch (status) {
  BookingRequestStatus.pending => 'Ожидает тренера',
  BookingRequestStatus.accepted => 'Принята',
  BookingRequestStatus.rejected => 'Отклонена',
  BookingRequestStatus.withdrawn => 'Отозвана',
  BookingRequestStatus.expired => 'Истекла',
};
