import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/social_models.dart';

/// Залы тренера в карточке каталога и публичном профиле. С [onTap] зал
/// нажимается (в каталоге — фильтр по залу).
class TrainerGymsList extends StatelessWidget {
  const TrainerGymsList({required this.gyms, this.onTap, super.key});

  final List<Gym> gyms;
  final ValueChanged<Gym>? onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final gym in gyms)
        InkWell(
          key: ValueKey('trainer-gym-${gym.id}'),
          onTap: onTap == null ? null : () => onTap!(gym),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: gym.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' · ${gym.fullAddress}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
