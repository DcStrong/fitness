import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../schedule/presentation/schedule_format.dart';
import '../../data/social_models.dart';
import '../../data/social_repository.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/specialty_chips.dart';
import '../widgets/trainer_gyms_list.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({required this.trainerId, super.key});

  final String trainerId;

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  PublicTrainer? _trainer;
  ReviewPage? _reviews;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = context.read<SocialRepository>();
      final results = await Future.wait<dynamic>([
        repository.getTrainer(widget.trainerId),
        repository.getTrainerReviews(widget.trainerId),
      ]);
      if (!mounted) return;
      setState(() {
        _trainer = results[0] as PublicTrainer;
        _reviews = results[1] as ReviewPage;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainer = _trainer;
    return Scaffold(
      appBar: FyTopBar(title: trainer?.displayName ?? 'Профиль тренера'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || trainer == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FyCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FyInfoBanner(
                        message:
                            'Профиль недоступен или больше не опубликован.',
                        icon: Icons.visibility_off_outlined,
                      ),
                      const SizedBox(height: 14),
                      FyPrimaryButton(label: 'Повторить', onPressed: _load),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  FyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ClipOval(
                            child: SafeNetworkImage(
                              url: trainer.avatarUrl,
                              width: 112,
                              height: 112,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          trainer.displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (trainer.city case final city?)
                          Text(
                            city,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        if (trainer.averageRating case final rating?) ...[
                          const SizedBox(height: 8),
                          Text(
                            '★ ${rating.toStringAsFixed(1)} · '
                            '${trainer.reviewCount ?? 0} отзывов',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (trainer.bio case final bio?) ...[
                          const SizedBox(height: 16),
                          Text(bio),
                        ],
                        if (trainer.specialties.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SpecialtyChips(
                            specialties: trainer.specialties,
                            alignment: WrapAlignment.center,
                          ),
                        ],
                        if (trainer.gyms.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Залы',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          TrainerGymsList(gyms: trainer.gyms),
                        ],
                        const SizedBox(height: 18),
                        if (trainer.isLinked == true)
                          FyPrimaryButton(
                            label: 'Выбрать тренировку',
                            onPressed: () => context.go('/schedule/book'),
                            showTrailingArrow: true,
                          )
                        else ...[
                          const FyInfoBanner(
                            message:
                                'Для записи нужно приглашение тренера. '
                                'Примите QR-код или ссылку приглашения.',
                            icon: Icons.qr_code_2_rounded,
                          ),
                          const SizedBox(height: 12),
                          FyPrimaryButton(
                            label: 'Принять приглашение',
                            onPressed: () => context.go('/invite/accept'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trainer.portfolio.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Портфолио',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...trainer.portfolio.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (item.imageUrl != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SafeNetworkImage(
                                    url: item.imageUrl,
                                    height: 180,
                                    icon: Icons.image_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (item.description case final description?) ...[
                                const SizedBox(height: 6),
                                Text(description),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Отзывы',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_reviews?.items.isEmpty != false)
                    const FyCard(
                      child: FyInfoBanner(
                        message: 'Отзывы пока отсутствуют или скрыты тренером.',
                        icon: Icons.reviews_outlined,
                      ),
                    )
                  else
                    ..._reviews!.items.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    review.reviewer.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text('★ ${review.rating}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDateTime(review.sessionStartsAt),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (review.text case final text?) ...[
                                const SizedBox(height: 8),
                                Text(text),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
