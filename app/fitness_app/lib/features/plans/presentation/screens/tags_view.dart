import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_icon_badge.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../widgets/plans_header.dart';
import '../cubit/tags_cubit.dart';
import '../cubit/tags_state.dart';

class TagsView extends StatefulWidget {
  const TagsView({super.key});

  @override
  State<TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<TagsView> {
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final tag = await context.read<TagsCubit>().createFromQuery();
    if (!mounted || tag == null) return;
    await context.push('/tags/${tag.id}');
    if (!mounted) return;
    await context.read<TagsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TagsCubit, TagsState>(
      listenWhen: (previous, next) =>
          previous.errorMessage != next.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<TagsCubit>();
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlansHeader(
                  title: 'Теги',
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/plans');
                    }
                  },
                ),
                Expanded(
                  child: switch (state.status) {
                    TagsStatus.initial || TagsStatus.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    TagsStatus.failure => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.errorMessage ?? 'Не удалось загрузить',
                        ),
                      ),
                    ),
                    TagsStatus.ready => RefreshIndicator(
                      onRefresh: cubit.load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          TextField(
                            key: const Key('tags-search'),
                            controller: _query,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Найти или создать тег, например Алина',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: cubit.setQuery,
                            onSubmitted: (_) {
                              if (state.canCreate) {
                                _create();
                                return;
                              }
                              final visible = cubit.state.visible;
                              if (visible.length == 1) {
                                context.push('/tags/${visible.first.id}');
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          if (state.canCreate)
                            Material(
                              key: const Key('tags-create'),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _create,
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const FyIconBadge(
                                        icon: Icons.add_rounded,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Создать «${state.query.trim()}» и привязать',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (state.canCreate) const SizedBox(height: 12),
                          if (state.tags.isEmpty && !state.canCreate)
                            const FyCard(
                              child: FyInfoBanner(
                                message:
                                    'Введите имя тега и создайте его — сразу можно привязать учеников, тренировки и упражнения.',
                                icon: Icons.sell_outlined,
                              ),
                            )
                          else
                            for (final tag in state.visible) ...[
                              FyCard(
                                key: Key('tag-row-${tag.id}'),
                                onTap: () => context.push('/tags/${tag.id}'),
                                child: Row(
                                  children: [
                                    const FyIconBadge(
                                      icon: Icons.sell_outlined,
                                      size: 44,
                                      iconSize: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tag.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if ((state.summaries[tag.id] ?? '')
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              state.summaries[tag.id]!,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (_summaryCount(
                                          state.summaries[tag.id],
                                        ) !=
                                        null) ...[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.mintSoft,
                                        child: Text(
                                          '${_summaryCount(state.summaries[tag.id])}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int? _summaryCount(String? summary) {
  if (summary == null || summary.isEmpty) return null;
  final match = RegExp(r'\d+').firstMatch(summary);
  if (match == null) return null;
  return int.parse(match.group(0)!);
}
