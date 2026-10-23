import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_avatar.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_square_icon_button.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../../more/presentation/more_page.dart';
import '../../../social/data/social_repository.dart';
import '../../../social/presentation/widgets/social_profile_editor.dart';
import '../../data/auth_models.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Profile (DS v2): who you are, your coach, shortcuts, the public profile
/// form and sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _ProfileBody(user: user);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.user});

  final AuthUser user;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  String? _displayName;
  List<RelationshipItem> _coaches = const [];

  bool get _isTrainer => widget.user.roles.contains('trainer');
  bool get _isStudent => widget.user.roles.contains('student');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Both are optional decorations: the screen works without them.
    try {
      final profile = await context.read<SocialRepository>().getOwnProfile();
      if (mounted) setState(() => _displayName = profile.displayName);
    } catch (_) {}
    if (!_isStudent || !mounted) return;
    try {
      final items = await context
          .read<InvitationsRepository>()
          .listRelationships();
      if (!mounted) return;
      setState(() {
        _coaches = items.where((r) => r.roleForViewer == 'student').toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final name = (_displayName ?? user.displayName)?.trim();
    final hasName = name != null && name.isNotEmpty;

    final shortcuts = <MoreMenuItem>[
      if (_isStudent)
        const MoreMenuItem(
          title: 'Мои заявки',
          subtitle: 'Ответы тренера на запись',
          icon: Icons.event_note_outlined,
          route: '/booking-requests/mine',
        ),
      if (_isStudent)
        const MoreMenuItem(
          title: 'Программа и прогресс',
          icon: Icons.track_changes_rounded,
          route: '/me/training',
        ),
      const MoreMenuItem(
        title: 'Отзывы',
        icon: Icons.star_outline_rounded,
        route: '/reviews',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            if (context.canPop()) ...[
              FySquareIconButton(
                buttonKey: const Key('profile-back'),
                tooltip: 'Назад',
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text('Профиль', style: theme.textTheme.headlineMedium),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          key: const Key('profile-who'),
          children: [
            FyAvatar(
              displayName: hasName ? name : null,
              email: user.email,
              size: 64,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? name : (_isTrainer ? 'Тренер' : 'Ученик'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        for (final coach in _coaches) ...[
          const SizedBox(height: 16),
          FyCard(
            key: Key('profile-coach-${coach.coachId}'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                FyAvatar(
                  displayName: coach.coachDisplayName,
                  email: coach.coachEmail,
                  size: 44,
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
                      Text('Ваш тренер', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: Key('profile-coach-chat-${coach.coachId}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                  ),
                  // One coach: the «Чат» tab is that thread; several: open
                  // this coach's thread directly.
                  onPressed: () => _coaches.length == 1
                      ? context.go('/chats')
                      : context.push('/chats/with/${coach.coachId}'),
                  child: const Text('Написать'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        MoreMenuGroup(items: shortcuts),
        const SizedBox(height: 24),
        SocialProfileEditor(isTrainer: _isTrainer),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('profile-logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Выйти'),
        ),
      ],
    );
  }
}
