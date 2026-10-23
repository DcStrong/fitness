import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../core/widgets/fy_avatar.dart';
import '../../../../core/widgets/person_name_email.dart';
import '../../../schedule/data/schedule_models.dart';
import '../home_format.dart';

/// Hero of the home screen: the nearest session and one action to open it.
/// Soft surface on purpose, so the call to action is the button, not the card.
class HomeNextSessionCard extends StatelessWidget {
  const HomeNextSessionCard({
    required this.session,
    required this.now,
    required this.userId,
    required this.isTrainer,
    super.key,
  });

  final TrainingSession? session;
  final DateTime now;
  final String userId;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    final current = session;
    return DecoratedBox(
      key: const Key('home-next-session'),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: current == null
            ? _EmptyHero(isTrainer: isTrainer)
            : _SessionHero(session: current, now: now, userId: userId),
      ),
    );
  }

  static TextStyle? leadStyle(ThemeData theme) => theme.textTheme.labelLarge
      ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600);
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({
    required this.session,
    required this.now,
    required this.userId,
  });

  final TrainingSession session;
  final DateTime now;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = DateTime.parse(session.startsAt).toLocal();
    final end = DateTime.parse(session.endsAt).toLocal();
    final (lead, accent) = formatHomeCountdown(
      start: start,
      end: end,
      now: now,
    );
    final viewerIsCoach = userId == session.coachId;
    final displayName = viewerIsCoach
        ? session.studentDisplayName
        : session.coachDisplayName;
    final email = viewerIsCoach ? session.studentEmail : session.coachEmail;
    final name = personPrimaryLabel(
      displayName: displayName,
      email: email,
      fallback: viewerIsCoach ? session.studentId : session.coachId,
    );
    final subtitle = session.workoutTitle?.trim().isNotEmpty == true
        ? session.workoutTitle!
        : personEmailCaption(displayName: displayName, email: email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Следующее занятие',
                style: HomeNextSessionCard.leadStyle(theme),
              ),
            ),
            Text(
              '${formatHomeTime(start)} – ${formatHomeTime(end)}',
              style: HomeNextSessionCard.leadStyle(theme),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          key: const Key('home-next-session-countdown'),
          TextSpan(
            text: lead,
            children: [
              TextSpan(
                text: accent,
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            FyAvatar(
              displayName: displayName,
              email: email,
              size: 44,
              onSurfaceTint: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const Key('home-next-session-open'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: () => context.push('/sessions/${session.id}'),
              child: const Text('Открыть'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.isTrainer});

  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Следующее занятие', style: HomeNextSessionCard.leadStyle(theme)),
        const SizedBox(height: 6),
        Text(
          'На этой неделе занятий больше нет',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('home-next-session-empty-action'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () =>
              context.go(isTrainer ? '/schedule' : '/schedule/book'),
          child: Text(isTrainer ? 'Открыть расписание' : 'Записаться'),
        ),
      ],
    );
  }
}
