import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../invitations/data/invitation_models.dart';
import '../../invitations/data/invitations_repository.dart';
import '../data/chat_models.dart';
import '../data/chat_realtime.dart';
import '../data/chats_repository.dart';
import 'chat_thread_page.dart';
import 'cubit/chat_list_cubit.dart';
import 'widgets/chat_widgets.dart';

/// Chat tab. Trainer: conversation list. Student: the thread with their coach
/// directly (board «Чат ученика»), or a list when there are several coaches.
class ChatsPage extends StatelessWidget {
  const ChatsPage({required this.isTrainer, super.key});

  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    if (!isTrainer) return const _StudentChatTab();
    return BlocProvider(
      create: (context) => ChatListCubit(
        repository: context.read<ChatsRepository>(),
        realtime: context.read<ChatRealtime>(),
      )..load(),
      child: const ChatListView(title: 'Чаты', searchHint: 'Поиск по ученикам'),
    );
  }
}

class _StudentChatTab extends StatefulWidget {
  const _StudentChatTab();

  @override
  State<_StudentChatTab> createState() => _StudentChatTabState();
}

class _StudentChatTabState extends State<_StudentChatTab> {
  late Future<List<RelationshipItem>> _coaches;

  @override
  void initState() {
    super.initState();
    _coaches = _load();
  }

  Future<List<RelationshipItem>> _load() async {
    final all = await context.read<InvitationsRepository>().listRelationships();
    return all.where((r) => r.roleForViewer == 'student').toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RelationshipItem>>(
      future: _coaches,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _ChatTabMessage(
            title: 'Чат',
            message: error is ApiException
                ? error.message
                : 'Не удалось загрузить тренеров',
            onRetry: () => setState(() => _coaches = _load()),
          );
        }
        final coaches = snapshot.data ?? const [];
        if (coaches.isEmpty) {
          return const _ChatTabMessage(
            title: 'Чат',
            message:
                'Здесь будет переписка с тренером. Он появится, когда вы '
                'примете приглашение или тренер подтвердит вашу заявку.',
          );
        }
        if (coaches.length == 1) {
          return ChatThreadPage(
            counterpartId: coaches.single.coachId,
            showBack: false,
          );
        }
        return BlocProvider(
          create: (context) => ChatListCubit(
            repository: context.read<ChatsRepository>(),
            realtime: context.read<ChatRealtime>(),
          )..load(),
          child: ChatListView(title: 'Чат', extraCoaches: coaches),
        );
      },
    );
  }
}

/// Conversation list (board «Чаты»).
class ChatListView extends StatelessWidget {
  const ChatListView({
    required this.title,
    this.searchHint,
    this.extraCoaches = const [],
    this.clock = DateTime.now,
    super.key,
  });

  final String title;

  /// Shows the search field when set.
  final String? searchHint;

  /// Student with several coaches: coaches without a conversation yet are
  /// listed after the conversations so a first message is one tap away.
  final List<RelationshipItem> extraCoaches;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myUserId = context.read<AuthCubit>().state.user?.id ?? '';
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ChatListCubit, ChatListState>(
          builder: (context, state) {
            final cubit = context.read<ChatListCubit>();
            final withChat = state.conversations
                .map((c) => c.counterpart.id)
                .toSet();
            final missing = extraCoaches
                .where((coach) => !withChat.contains(coach.coachId))
                .toList();
            return RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xl,
                  AppSpacing.screen,
                  AppSpacing.xxl,
                ),
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (searchHint != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      key: const Key('chat-search'),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                      onChanged: cubit.search,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  ..._content(context, state, myUserId, missing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    ChatListState state,
    String myUserId,
    List<RelationshipItem> missing,
  ) {
    final theme = Theme.of(context);
    switch (state.status) {
      case ChatListStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case ChatListStatus.failure:
        return [
          const SizedBox(height: AppSpacing.xl),
          Text(
            state.errorMessage ?? 'Не удалось загрузить переписки',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FySecondaryButton(
            label: 'Повторить',
            onPressed: context.read<ChatListCubit>().load,
          ),
        ];
      case ChatListStatus.ready:
        if (state.conversations.isEmpty && missing.isEmpty) {
          return [
            const SizedBox(height: AppSpacing.xl),
            _EmptyHint(
              text: state.query.isNotEmpty
                  ? 'Никого не нашли'
                  : 'Переписок пока нет. Написать ученику можно из его '
                        'карточки в разделе «Ученики».',
            ),
          ];
        }
        final now = clock();
        return [
          for (final conversation in state.conversations)
            ChatConversationRow(
              key: Key('chat-row-${conversation.id}'),
              conversation: conversation,
              myUserId: myUserId,
              now: now,
              onTap: () => context.push('/chats/${conversation.id}'),
            ),
          for (final coach in missing)
            ChatConversationRow(
              key: Key('chat-row-coach-${coach.coachId}'),
              conversation: ChatConversation(
                id: '',
                coachId: coach.coachId,
                studentId: coach.studentId,
                isCoach: false,
                counterpart: ChatCounterpart(
                  id: coach.coachId,
                  email: coach.coachEmail,
                  displayName: coach.coachDisplayName,
                ),
              ),
              myUserId: myUserId,
              now: now,
              onTap: () => context.push('/chats/with/${coach.coachId}'),
            ),
        ];
    }
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTabMessage extends StatelessWidget {
  const _ChatTabMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xl,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FyCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const FyIconBadge(
                    icon: Icons.chat_bubble_outline_rounded,
                    size: 56,
                    iconSize: 28,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FySecondaryButton(label: 'Повторить', onPressed: onRetry),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
