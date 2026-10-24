import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_input_card.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../data/social_models.dart';
import '../../data/social_repository.dart';
import '../bloc/trainers_bloc.dart';
import '../widgets/safe_network_image.dart';
import '../widgets/specialty_chips.dart';

class TrainersPage extends StatelessWidget {
  const TrainersPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        TrainersBloc(repository: context.read<SocialRepository>())
          ..add(const TrainersStarted()),
    child: const TrainersView(),
  );
}

class TrainersView extends StatefulWidget {
  const TrainersView({super.key});

  @override
  State<TrainersView> createState() => _TrainersViewState();
}

class _TrainersViewState extends State<TrainersView> {
  final _query = TextEditingController();
  final _specialty = TextEditingController();
  String? _mode;

  @override
  void dispose() {
    _query.dispose();
    _specialty.dispose();
    super.dispose();
  }

  void _apply() => context.read<TrainersBloc>().add(
    TrainersFiltersChanged(
      query: _query.text,
      specialty: _specialty.text,
      mode: _mode,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FyTopBar(title: 'Тренеры'),
      body: BlocConsumer<TrainersBloc, TrainersState>(
        listenWhen: (previous, current) =>
            previous.error != current.error &&
            current.error != null &&
            current.items.isNotEmpty,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось загрузить ещё')),
            ),
        builder: (context, state) => RefreshIndicator(
          onRefresh: () async {
            context.read<TrainersBloc>().add(const TrainersRetryRequested());
            await context.read<TrainersBloc>().stream.firstWhere(
              (next) => next.status != TrainersStatus.loading,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              FyInputCard(
                label: 'Имя или город',
                icon: Icons.search_rounded,
                controller: _query,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _apply(),
              ),
              const SizedBox(height: 10),
              FyInputCard(
                label: 'Специализация',
                icon: Icons.fitness_center_rounded,
                controller: _specialty,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _apply(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Все форматы'),
                    selected: _mode == null,
                    onSelected: (_) => setState(() => _mode = null),
                  ),
                  ChoiceChip(
                    label: const Text('Онлайн'),
                    selected: _mode == 'online',
                    onSelected: (_) => setState(() => _mode = 'online'),
                  ),
                  ChoiceChip(
                    label: const Text('Очно'),
                    selected: _mode == 'offline',
                    onSelected: (_) => setState(() => _mode = 'offline'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FyPrimaryButton(label: 'Найти', onPressed: _apply),
              const SizedBox(height: 20),
              if (state.status == TrainersStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == TrainersStatus.failure)
                FyCard(
                  child: Column(
                    children: [
                      const FyInfoBanner(
                        message: 'Не удалось загрузить тренеров.',
                        icon: Icons.sync_problem_rounded,
                      ),
                      const SizedBox(height: 12),
                      FyPrimaryButton(
                        label: 'Повторить',
                        onPressed: () => context.read<TrainersBloc>().add(
                          const TrainersRetryRequested(),
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.items.isEmpty)
                const FyCard(
                  child: FyInfoBanner(
                    message: 'По этим фильтрам тренеры не найдены.',
                    icon: Icons.person_search_outlined,
                  ),
                )
              else ...[
                ...state.items.map(
                  (trainer) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TrainerCard(trainer: trainer),
                  ),
                ),
                if (state.hasNext)
                  FyPrimaryButton(
                    label: 'Показать ещё',
                    isLoading: state.loadingMore,
                    onPressed: () => context.read<TrainersBloc>().add(
                      const TrainersNextPageRequested(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({required this.trainer});

  final PublicTrainer trainer;

  @override
  Widget build(BuildContext context) => FyCard(
    onTap: () => context.push('/trainers/${trainer.id}'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SafeNetworkImage(
            url: trainer.avatarUrl,
            width: 72,
            height: 72,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trainer.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (trainer.city case final city?) ...[
                const SizedBox(height: 3),
                Text(city, style: const TextStyle(color: AppColors.textMuted)),
              ],
              if (trainer.specialties.isNotEmpty) ...[
                const SizedBox(height: 8),
                SpecialtyChips(specialties: trainer.specialties),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (trainer.averageRating case final rating?) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                    Text(
                      '${rating.toStringAsFixed(1)}'
                      '${trainer.reviewCount == null ? '' : ' (${trainer.reviewCount})'}',
                    ),
                  ] else
                    const Text(
                      'Рейтинг скрыт',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
