import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/fy_square_icon_button.dart';

/// DS v2 screen header for the training screens: own row instead of
/// FyTopBar — optional back button, title, square action buttons.
class PlansHeader extends StatelessWidget {
  const PlansHeader({
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          if (showBack) ...[
            FySquareIconButton(
              buttonKey: const Key('plans-back'),
              tooltip: 'Назад',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack ?? () => context.pop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: showBack ? 20 : 24),
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}
