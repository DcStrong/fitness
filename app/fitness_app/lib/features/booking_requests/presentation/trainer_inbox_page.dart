import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fy_button.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../schedule/presentation/schedule_format.dart';
import '../../schedule/presentation/widgets/occupancy_datetime_picker.dart';
import '../../social/data/social_models.dart';
import '../../social/data/social_repository.dart';
import '../data/booking_request_models.dart';
import '../data/booking_requests_repository.dart';
import 'cubit/trainer_inbox_cubit.dart';
import 'widgets/fy_booking_request_card.dart';
import '../../../core/widgets/fy_top_bar.dart';

class TrainerInboxPage extends StatelessWidget {
  const TrainerInboxPage({this.embedded = false, super.key});

  /// Inside the schedule tabs: the page header is already there.
  final bool embedded;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        TrainerInboxCubit(repository: context.read<BookingRequestsRepository>())
          ..load(),
    child: TrainerInboxView(embedded: embedded),
  );
}

class TrainerInboxView extends StatelessWidget {
  const TrainerInboxView({this.embedded = false, super.key});

  final bool embedded;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: embedded ? null : const FyTopBar(title: 'Заявки'),
    body: BlocConsumer<TrainerInboxCubit, TrainerInboxState>(
      listenWhen: (previous, current) =>
          current.message != null && current.message != previous.message,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) {
        if (state.status == TrainerInboxStatus.loading ||
            state.status == TrainerInboxStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TrainerInboxStatus.failure && state.items.isEmpty) {
          return Center(
            child: FyCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FyInfoBanner(
                    message: 'Не удалось загрузить заявки.',
                    icon: Icons.sync_problem_rounded,
                  ),
                  TextButton(
                    onPressed: context.read<TrainerInboxCubit>().load,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: context.read<TrainerInboxCubit>().refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: const [
                FyCard(
                  child: FyInfoBanner(
                    message: 'Новых заявок пока нет.',
                    icon: Icons.inbox_outlined,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<TrainerInboxCubit>().refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Нужно ответить',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final request in state.items) ...[
                _InboxCard(
                  request: request,
                  processing: state.processingId == request.id,
                ),
                const SizedBox(height: 12),
              ],
              if (state.hasNext)
                FyButton.secondary(
                  label: 'Показать ещё',
                  size: FyButtonSize.medium,
                  onPressed: state.status == TrainerInboxStatus.submitting
                      ? null
                      : context.read<TrainerInboxCubit>().loadMore,
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.request, required this.processing});

  final BookingRequest request;
  final bool processing;

  @override
  Widget build(BuildContext context) => FyBookingRequestCard(
    request: request,
    processing: processing,
    onOpen: () =>
        context.push('/booking-requests/${request.id}', extra: request),
    onAccept: () => context.read<TrainerInboxCubit>().accept(request.id),
    onAlternate: () => _alternate(context),
    onReject: () => _reject(context),
  );

  Future<void> _reject(BuildContext context) async {
    final result = await showDialog<(BookingRequestRejectionReason, String)>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (result != null && context.mounted) {
      await context.read<TrainerInboxCubit>().reject(
        request.id,
        reason: result.$1,
        comment: result.$2,
      );
    }
  }

  Future<void> _alternate(BuildContext context) async {
    LinkedContacts? contacts;
    String? error;
    try {
      contacts = await context.read<SocialRepository>().getLinkedContacts(
        request.studentId,
      );
    } catch (caught) {
      error = caught.toString();
    }
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _AlternateSheet(contacts: contacts, error: error),
    );
    if (selected != null && context.mounted) {
      await context.read<TrainerInboxCubit>().alternate(request.id, selected);
    }
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _comment = TextEditingController();
  var _reason = BookingRequestRejectionReason.timeUnavailable;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Отклонить заявку'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BookingRequestRejectionReason>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Причина'),
            items: const [
              DropdownMenuItem(
                value: BookingRequestRejectionReason.timeUnavailable,
                child: Text('Время недоступно'),
              ),
              DropdownMenuItem(
                value: BookingRequestRejectionReason.plansChanged,
                child: Text('Планы изменились'),
              ),
              DropdownMenuItem(
                value: BookingRequestRejectionReason.other,
                child: Text('Другое'),
              ),
            ],
            onChanged: (value) => setState(() => _reason = value!),
          ),
          TextField(
            controller: _comment,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Комментарий ученику (необязательно)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FyButton.danger(
        label: 'Отклонить',
        size: FyButtonSize.medium,
        fullWidth: false,
        onPressed: () => Navigator.pop(context, (_reason, _comment.text)),
      ),
    ],
  );
}

class _AlternateSheet extends StatefulWidget {
  const _AlternateSheet({this.contacts, this.error});
  final LinkedContacts? contacts;
  final String? error;

  @override
  State<_AlternateSheet> createState() => _AlternateSheetState();
}

class _AlternateSheetState extends State<_AlternateSheet> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Согласуйте другое время',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Свяжитесь с учеником вне Fitness Yoda. После согласования '
            'укажите окончательное время — подтверждение ученика не потребуется.',
          ),
          const SizedBox(height: 12),
          if (widget.error != null)
            FyInfoBanner(message: widget.error!, icon: Icons.error_outline)
          else ...[
            if (widget.contacts?.phone case final phone?)
              Text('Телефон: $phone'),
            if (widget.contacts?.telegramUsername case final username?)
              Text('Telegram: @$username'),
            Text('Email: ${widget.contacts?.email ?? '—'}'),
          ],
          const SizedBox(height: 16),
          FyButton.secondary(
            label: _selected == null
                ? 'Выбрать дату и время'
                : formatDateTime(_selected!),
            icon: Icons.event_outlined,
            size: FyButtonSize.medium,
            onPressed: _pick,
          ),
          const SizedBox(height: 8),
          FyButton.primary(
            label: 'Назначить это время',
            size: FyButtonSize.medium,
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    ),
  );

  Future<void> _pick() async {
    final picked = await showOccupancyDateTimePicker(
      context: context,
      initialDate: _selected ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selected = picked);
    }
  }
}
