import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/person_name_email.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/presentation/screens/coach_book_for_student_screen.dart';
import '../data/chat_models.dart';
import '../data/chat_realtime.dart';
import '../data/chats_repository.dart';
import 'chat_format.dart';
import 'cubit/chat_thread_cubit.dart';
import 'widgets/chat_widgets.dart';

/// Route entry: builds the cubit from app-level repositories.
class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({
    this.conversationId,
    this.counterpartId,
    this.showBack = true,
    super.key,
  }) : assert(conversationId != null || counterpartId != null);

  final String? conversationId;
  final String? counterpartId;

  /// The student's «Чат» tab shows the thread as the tab root, without back.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      key: ValueKey(conversationId ?? counterpartId),
      create: (context) => ChatThreadCubit(
        repository: context.read<ChatsRepository>(),
        realtime: context.read<ChatRealtime>(),
        myUserId: myUserId,
        conversationId: conversationId,
        counterpartId: counterpartId,
      )..load(),
      child: ChatThreadView(
        myUserId: myUserId,
        showBack: showBack,
        loadNextSession: (conversation) =>
            _nextSession(context.read<ScheduleRepository>(), conversation),
      ),
    );
  }
}

/// Next booked session of the pair for the header subtitle; null on error.
Future<DateTime?> _nextSession(
  ScheduleRepository schedule,
  ChatConversation conversation,
) async {
  try {
    final now = DateTime.now();
    final sessions = await schedule.listSessions(
      status: 'booked',
      from: now,
      to: now.add(const Duration(days: 60)),
      studentId: conversation.isCoach ? conversation.studentId : null,
    );
    final starts =
        sessions
            .where(
              (s) =>
                  s.coachId == conversation.coachId &&
                  s.studentId == conversation.studentId,
            )
            .map((s) => DateTime.tryParse(s.startsAt)?.toLocal())
            .whereType<DateTime>()
            .where((start) => start.isAfter(now))
            .toList()
          ..sort();
    return starts.isEmpty ? null : starts.first;
  } catch (_) {
    return null;
  }
}

class ChatThreadView extends StatefulWidget {
  const ChatThreadView({
    required this.myUserId,
    this.showBack = true,
    this.loadNextSession,
    this.clock = DateTime.now,
    super.key,
  });

  final String myUserId;
  final bool showBack;
  final Future<DateTime?> Function(ChatConversation conversation)?
  loadNextSession;
  final DateTime Function() clock;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  Future<DateTime?>? _nextSession;
  String? _nextSessionFor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ChatThreadCubit, ChatThreadState>(
          builder: (context, state) {
            final conversation = state.conversation;
            if (conversation != null &&
                _nextSessionFor != conversation.id &&
                widget.loadNextSession != null) {
              _nextSessionFor = conversation.id;
              _nextSession = widget.loadNextSession!(conversation);
            }
            return Column(
              children: [
                _Header(
                  conversation: conversation,
                  showBack: widget.showBack,
                  nextSession: _nextSession,
                  now: widget.clock(),
                ),
                Expanded(child: _body(context, state)),
                if (state.status == ChatThreadStatus.ready)
                  SafeArea(
                    top: false,
                    child: ChatComposer(
                      onSend: context.read<ChatThreadCubit>().send,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChatThreadState state) {
    final theme = Theme.of(context);
    switch (state.status) {
      case ChatThreadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ChatThreadStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Не удалось открыть переписку',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                FySecondaryButton(
                  label: 'Повторить',
                  onPressed: context.read<ChatThreadCubit>().load,
                ),
              ],
            ),
          ),
        );
      case ChatThreadStatus.ready:
        if (state.messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Text(
                'Сообщений пока нет. Напишите первым.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        return _MessageList(
          state: state,
          myUserId: widget.myUserId,
          now: widget.clock(),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.conversation,
    required this.showBack,
    required this.nextSession,
    required this.now,
  });

  final ChatConversation? conversation;
  final bool showBack;
  final Future<DateTime?>? nextSession;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final fallbackSubtitle = c == null
        ? ''
        : c.isCoach
        ? 'Ученик'
        : 'Ваш тренер';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            FySquareIconButton(
              buttonKey: const Key('chat-back'),
              tooltip: 'Назад',
              icon: Icons.arrow_back_rounded,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/chats'),
            ),
            const SizedBox(width: 10),
          ],
          if (c != null) ...[
            FyAvatar(
              displayName: c.counterpart.displayName,
              email: c.counterpart.email,
              size: 40,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c == null
                      ? 'Переписка'
                      : personPrimaryLabel(
                          displayName: c.counterpart.displayName,
                          email: c.counterpart.email,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (c != null)
                  FutureBuilder<DateTime?>(
                    future: nextSession,
                    builder: (context, snapshot) {
                      final next = snapshot.data;
                      return Text(
                        next == null
                            ? fallbackSubtitle
                            : 'Следующее: ${formatChatNextSession(next, now: now)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (c != null && c.isCoach) ...[
            const SizedBox(width: 10),
            FySquareIconButton(
              buttonKey: const Key('chat-book'),
              tooltip: 'Записать на занятие',
              icon: Icons.event_available_rounded,
              onPressed: () => context.push(
                '/schedule/book-for-student',
                extra: CoachBookPrefill(studentId: c.studentId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.myUserId,
    required this.now,
  });

  final ChatThreadState state;
  final String myUserId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatThreadCubit>();
    final entries = <Widget>[];
    DateTime? day;
    for (final message in state.messages) {
      final local = message.createdAt.toLocal();
      final messageDay = DateTime(local.year, local.month, local.day);
      if (day != messageDay) {
        day = messageDay;
        entries.add(ChatDayDivider(label: formatChatDay(local, now: now)));
      }
      entries.add(
        message.isSystem
            ? ChatSystemCard(
                message: message,
                onOpenSession: message.payload?.sessionId == null
                    ? null
                    : () => context.push(
                        '/sessions/${message.payload!.sessionId}',
                      ),
              )
            : ChatBubble(
                key: ValueKey(message.clientId ?? message.id),
                message: message,
                mine: message.senderId == myUserId,
                onRetry: message.clientId == null
                    ? null
                    : () => cubit.retry(message.clientId!),
              ),
      );
    }
    final reversed = entries.reversed.toList();
    final extra = state.hasOlder ? 1 : 0;

    // Reversed list keeps the newest message pinned above the composer.
    return ListView.separated(
      key: const Key('chat-messages'),
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: reversed.length + extra,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= reversed.length) {
          // Reached the oldest loaded message: fetch the previous page.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => cubit.loadOlder(),
          );
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return reversed[index];
      },
    );
  }
}
