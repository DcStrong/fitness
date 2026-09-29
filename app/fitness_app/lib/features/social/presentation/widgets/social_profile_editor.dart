import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_input_card.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../data/social_models.dart';
import '../../data/social_repository.dart';
import 'safe_network_image.dart';

class SocialProfileEditor extends StatefulWidget {
  const SocialProfileEditor({required this.isTrainer, super.key});

  final bool isTrainer;

  @override
  State<SocialProfileEditor> createState() => _SocialProfileEditorState();
}

class _SocialProfileEditorState extends State<SocialProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _avatar = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _specialties = TextEditingController();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();
  final Set<PreferredContactChannel> _preferredChannels = {};
  ProfilePrivacy _privacy = const ProfilePrivacy();
  OwnerProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _avatar.dispose();
    _bio.dispose();
    _city.dispose();
    _specialties.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<SocialRepository>().getOwnProfile();
      if (!mounted) return;
      _name.text = profile.displayName ?? '';
      _avatar.text = profile.avatarUrl ?? '';
      _bio.text = profile.bio ?? '';
      _city.text = profile.city ?? '';
      _specialties.text = profile.specialties.join(', ');
      _phone.text = profile.phone ?? '';
      _telegram.text = profile.telegramUsername ?? '';
      _preferredChannels
        ..clear()
        ..addAll(profile.preferredContactChannels);
      setState(() {
        _profile = profile;
        _privacy = profile.privacy;
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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = context.read<SocialRepository>();
      await repository.updateOwnProfile(
        displayName: _name.text,
        avatarUrl: _avatar.text,
        bio: _bio.text,
        city: widget.isTrainer ? _city.text : null,
        specialties: widget.isTrainer
            ? _specialties.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .take(10)
                  .toList()
            : const [],
        trainingModes: widget.isTrainer
            ? [
                if (_profile?.trainingModes.contains('online') == true)
                  'online',
                if (_profile?.trainingModes.contains('offline') == true)
                  'offline',
              ]
            : const [],
        phone: _phone.text,
        telegramUsername: _telegram.text,
        preferredContactChannels: _preferredChannels.toList(),
      );
      final profile = await repository.updatePrivacy(
        widget.isTrainer ? _privacy : _privacy.copyWith(isDiscoverable: false),
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _privacy = profile.privacy;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  void _toggleMode(String mode, bool selected) {
    final modes = [...?_profile?.trainingModes];
    selected ? modes.add(mode) : modes.remove(mode);
    setState(() {
      _profile = OwnerProfile(
        userId: _profile?.userId ?? '',
        displayName: _profile?.displayName,
        avatarUrl: _profile?.avatarUrl,
        bio: _profile?.bio,
        city: _profile?.city,
        specialties: _profile?.specialties ?? const [],
        trainingModes: modes.toSet().toList(),
        phone: _profile?.phone,
        telegramUsername: _profile?.telegramUsername,
        preferredContactChannels:
            _profile?.preferredContactChannels ?? const [],
        email: _profile?.email ?? '',
        privacy: _privacy,
        portfolio: _profile?.portfolio ?? const [],
        averageRating: _profile?.averageRating,
        reviewCount: _profile?.reviewCount ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FyCard(child: Center(child: CircularProgressIndicator()));
    }
    if (_profile == null) {
      return FyCard(
        child: Column(
          children: [
            const FyInfoBanner(
              message: 'Не удалось загрузить социальный профиль.',
              icon: Icons.sync_problem_rounded,
            ),
            const SizedBox(height: 12),
            FyPrimaryButton(label: 'Повторить', onPressed: _load),
          ],
        ),
      );
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Публичный профиль',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipOval(
                    child: SafeNetworkImage(
                      url: _avatar.text,
                      width: 88,
                      height: 88,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FyInputCard(
                  label: 'Имя',
                  icon: Icons.badge_outlined,
                  controller: _name,
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length >= 2 && length <= 80
                        ? null
                        : 'От 2 до 80 символов';
                  },
                ),
                const SizedBox(height: 10),
                FyInputCard(
                  label: 'HTTPS-ссылка на фото',
                  icon: Icons.image_outlined,
                  controller: _avatar,
                  keyboardType: TextInputType.url,
                  validator: _optionalHttps,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'О себе',
                    alignLabelWithHint: true,
                  ),
                ),
                if (widget.isTrainer) ...[
                  const SizedBox(height: 10),
                  FyInputCard(
                    label: 'Город',
                    icon: Icons.location_city_outlined,
                    controller: _city,
                    validator: (value) => (value?.length ?? 0) <= 120
                        ? null
                        : 'Не более 120 символов',
                  ),
                  const SizedBox(height: 10),
                  FyInputCard(
                    label: 'Специализации через запятую',
                    icon: Icons.fitness_center_rounded,
                    controller: _specialties,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Онлайн'),
                        selected: _profile!.trainingModes.contains('online'),
                        onSelected: (value) => _toggleMode('online', value),
                      ),
                      FilterChip(
                        label: const Text('Очно'),
                        selected: _profile!.trainingModes.contains('offline'),
                        onSelected: (value) => _toggleMode('offline', value),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Мои контакты',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Контакты видны только связанным тренерам и ученикам. '
                  'Email используется как запасной способ связи.',
                ),
                const SizedBox(height: 12),
                FyInputCard(
                  label: 'Телефон',
                  icon: Icons.phone_outlined,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return _preferredChannels.contains(
                            PreferredContactChannel.phone,
                          )
                          ? 'Укажите телефон для выбранного канала'
                          : null;
                    }
                    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(text)
                        ? null
                        : 'Введите телефон в формате +79991234567';
                  },
                ),
                const SizedBox(height: 10),
                FyInputCard(
                  label: 'Telegram username',
                  icon: Icons.send_outlined,
                  controller: _telegram,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return _preferredChannels.contains(
                            PreferredContactChannel.telegram,
                          )
                          ? 'Укажите Telegram для выбранного канала'
                          : null;
                    }
                    return RegExp(
                          r'^[A-Za-z][A-Za-z0-9_]{4,31}$',
                        ).hasMatch(text)
                        ? null
                        : 'Введите username без @ и ссылки';
                  },
                ),
                const SizedBox(height: 10),
                Text('Предпочтительные каналы: ${_profile!.email}'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final channel in PreferredContactChannel.values)
                      FilterChip(
                        label: Text(switch (channel) {
                          PreferredContactChannel.phone => 'Телефон',
                          PreferredContactChannel.telegram => 'Telegram',
                          PreferredContactChannel.email => 'Email',
                        }),
                        selected: _preferredChannels.contains(channel),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _preferredChannels.add(channel)
                              : _preferredChannels.remove(channel);
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Приватность',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.isTrainer) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Показывать в каталоге'),
                    subtitle: const Text(
                      'Для публикации укажите имя. Изменение действует сразу.',
                    ),
                    value: _privacy.isDiscoverable,
                    onChanged: (value) => setState(
                      () => _privacy = _privacy.copyWith(isDiscoverable: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Показывать рейтинг'),
                    value: _privacy.showRating,
                    onChanged: (value) => setState(
                      () => _privacy = _privacy.copyWith(showRating: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Показывать отзывы'),
                    value: _privacy.showReviews,
                    onChanged: (value) => setState(
                      () => _privacy = _privacy.copyWith(showReviews: value),
                    ),
                  ),
                ] else
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Показывать моё имя в отзывах'),
                    subtitle: const Text(
                      'Если выключить, публично будет указано «Ученик».',
                    ),
                    value: _privacy.showReviewerName,
                    onChanged: (value) => setState(
                      () =>
                          _privacy = _privacy.copyWith(showReviewerName: value),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            FyInfoBanner(message: _error!, icon: Icons.error_outline_rounded),
          ],
          const SizedBox(height: 16),
          FyPrimaryButton(
            label: 'Сохранить профиль',
            isLoading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/reviews'),
            icon: const Icon(Icons.reviews_outlined),
            label: Text(widget.isTrainer ? 'Полученные отзывы' : 'Мои отзывы'),
          ),
          if (widget.isTrainer) ...[
            const SizedBox(height: 20),
            _PortfolioEditor(profile: _profile!, onChanged: _load),
          ],
        ],
      ),
    );
  }

  String? _optionalHttps(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri?.scheme == 'https' && uri?.host.isNotEmpty == true
        ? null
        : 'Нужна корректная HTTPS-ссылка';
  }
}

class _PortfolioEditor extends StatelessWidget {
  const _PortfolioEditor({required this.profile, required this.onChanged});

  final OwnerProfile profile;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Портфолио',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Добавить работу',
            onPressed: profile.portfolio.length >= 20
                ? null
                : () => _edit(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      if (profile.portfolio.isEmpty)
        const FyCard(
          child: FyInfoBanner(
            message: 'Добавьте до 20 работ в портфолио.',
            icon: Icons.collections_outlined,
          ),
        )
      else
        ...profile.portfolio.indexed.map((entry) {
          final index = entry.$1;
          final item = entry.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FyCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Выше',
                    onPressed: index == 0
                        ? null
                        : () => _move(context, index, -1),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ниже',
                    onPressed: index == profile.portfolio.length - 1
                        ? null
                        : () => _move(context, index, 1),
                    icon: const Icon(Icons.arrow_downward_rounded),
                  ),
                  IconButton(
                    tooltip: 'Изменить',
                    onPressed: () => _edit(context, item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () => _delete(context, item),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        }),
    ],
  );

  Future<void> _move(BuildContext context, int index, int delta) async {
    final items = [...profile.portfolio];
    final item = items.removeAt(index);
    items.insert(index + delta, item);
    await context.read<SocialRepository>().reorderPortfolio(
      items.map((item) => item.id).whereType<String>().toList(),
    );
    await onChanged();
  }

  Future<void> _delete(BuildContext context, PortfolioItem item) async {
    if (item.id == null) return;
    await context.read<SocialRepository>().deletePortfolioItem(item.id!);
    await onChanged();
  }

  Future<void> _edit(BuildContext context, [PortfolioItem? item]) async {
    final title = TextEditingController(text: item?.title);
    final description = TextEditingController(text: item?.description);
    final image = TextEditingController(text: item?.imageUrl);
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Новая работа' : 'Изменить работу'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: description,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              TextField(
                controller: image,
                decoration: const InputDecoration(
                  labelText: 'HTTPS-ссылка на изображение',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final imageUri = Uri.tryParse(image.text.trim());
              final imageValid =
                  image.text.trim().isEmpty ||
                  (imageUri?.scheme == 'https' &&
                      imageUri?.host.isNotEmpty == true);
              if (title.text.trim().isNotEmpty && imageValid) {
                Navigator.pop(dialogContext, (
                  title.text,
                  description.text,
                  image.text,
                ));
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    title.dispose();
    description.dispose();
    image.dispose();
    if (result == null || !context.mounted) return;
    final repository = context.read<SocialRepository>();
    if (item?.id case final id?) {
      await repository.updatePortfolioItem(
        id: id,
        title: result.$1,
        description: result.$2,
        imageUrl: result.$3,
      );
    } else {
      await repository.createPortfolioItem(
        title: result.$1,
        description: result.$2,
        imageUrl: result.$3,
      );
    }
    await onChanged();
  }
}
