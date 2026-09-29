import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../schedule/presentation/schedule_format.dart';
import '../../data/social_models.dart';
import '../../data/social_repository.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({required this.isTrainer, super.key});

  final bool isTrainer;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<EligibleReviewSession> _eligible = const [];
  List<SessionReview> _mine = const [];
  List<SessionReview> _received = const [];
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
      if (widget.isTrainer) {
        final page = await context.read<SocialRepository>().getReceivedReviews(
          limit: 50,
        );
        if (!mounted) return;
        setState(() {
          _received = page.items;
          _loading = false;
        });
      } else {
        final repository = context.read<SocialRepository>();
        final results = await Future.wait<dynamic>([
          repository.getEligibleReviews(),
          repository.getMyReviews(),
        ]);
        if (!mounted) return;
        setState(() {
          _eligible = results[0] as List<EligibleReviewSession>;
          _mine = results[1] as List<SessionReview>;
          _loading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FyTopBar(title: widget.isTrainer ? 'Отзывы обо мне' : 'Мои отзывы'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FyCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FyInfoBanner(
                      message: 'Не удалось загрузить отзывы.',
                      icon: Icons.sync_problem_rounded,
                    ),
                    const SizedBox(height: 12),
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
              children: widget.isTrainer
                  ? _reviewList(_received, editable: false)
                  : [
                      Text(
                        'Можно оценить',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_eligible.isEmpty)
                        const FyCard(
                          child: FyInfoBanner(
                            message: 'Нет завершённых тренировок без отзыва.',
                            icon: Icons.task_alt_rounded,
                          ),
                        )
                      else
                        ..._eligible.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FyCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    session.coachDisplayName ?? 'Тренер',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(formatDateTime(session.startsAt)),
                                  const SizedBox(height: 10),
                                  FyPrimaryButton(
                                    label: 'Оставить отзыв',
                                    onPressed: () => context
                                        .push<bool>(
                                          '/reviews/new?sessionId=${session.sessionId}',
                                        )
                                        .then((saved) {
                                          if (saved == true) _load();
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Опубликованные',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._reviewList(_mine, editable: true),
                    ],
            ),
          ),
  );

  List<Widget> _reviewList(
    List<SessionReview> reviews, {
    required bool editable,
  }) {
    if (reviews.isEmpty) {
      return const [
        FyCard(
          child: FyInfoBanner(
            message: 'Отзывов пока нет.',
            icon: Icons.reviews_outlined,
          ),
        ),
      ];
    }
    return reviews
        .map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.reviewer.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('★ ${review.rating}'),
                    ],
                  ),
                  Text(formatDateTime(review.sessionStartsAt)),
                  if (review.text case final text?) ...[
                    const SizedBox(height: 8),
                    Text(text),
                  ],
                  if (editable && review.id != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context
                          .push<bool>('/reviews/${review.id}/edit')
                          .then((saved) {
                            if (saved == true) _load();
                          }),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Изменить'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}

class ReviewEditorScreen extends StatefulWidget {
  const ReviewEditorScreen({this.sessionId, this.reviewId, super.key});

  final String? sessionId;
  final String? reviewId;

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  final _text = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.reviewId != null) _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reviews = await context.read<SocialRepository>().getMyReviews();
      final review = reviews.where((item) => item.id == widget.reviewId).first;
      if (!mounted) return;
      _text.text = review.text ?? '';
      setState(() {
        _rating = review.rating;
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = context.read<SocialRepository>();
      if (widget.reviewId case final id?) {
        await repository.updateReview(
          id: id,
          rating: _rating,
          text: _text.text,
        );
      } else if (widget.sessionId case final id?) {
        await repository.createReview(
          sessionId: id,
          rating: _rating,
          text: _text.text,
        );
      } else {
        throw StateError('Не выбрана тренировка');
      }
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FyTopBar(
      title: widget.reviewId == null ? 'Новый отзыв' : 'Изменить отзыв',
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Оценка',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var rating = 1; rating <= 5; rating++)
                          IconButton(
                            tooltip: '$rating',
                            onPressed: () => setState(() => _rating = rating),
                            icon: Icon(
                              rating <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 34,
                            ),
                          ),
                      ],
                    ),
                    TextField(
                      controller: _text,
                      maxLength: 2000,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Текст (необязательно)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                FyInfoBanner(
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                ),
              ],
              const SizedBox(height: 16),
              FyPrimaryButton(
                label: 'Сохранить отзыв',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
  );
}
