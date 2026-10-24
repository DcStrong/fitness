import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_input_card.dart';
import '../../data/social_models.dart';
import '../cubit/gyms_cubit.dart';

/// Блок «Залы, где я тренирую». Залы добавляются и удаляются сразу
/// (отдельно от кнопки «Сохранить профиль»). Требует [GymsCubit] выше по дереву.
class GymsEditor extends StatefulWidget {
  const GymsEditor({this.defaultCity, this.onInputChanged, super.key});

  final String? defaultCity;

  /// Вызывается при вводе в форму нового зала (для отслеживания изменений).
  final VoidCallback? onInputChanged;

  @override
  State<GymsEditor> createState() => GymsEditorState();
}

class GymsEditorState extends State<GymsEditor> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  late final TextEditingController _city;
  final _district = TextEditingController();

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.defaultCity ?? '');
    _initialCity = _city.text;
    for (final controller in [_name, _address, _district, _city]) {
      controller.addListener(() => widget.onInputChanged?.call());
    }
  }

  late final String _initialCity;

  /// Пользователь начал вводить новый зал, но ещё не добавил его.
  bool get hasInput =>
      _name.text.trim().isNotEmpty ||
      _address.text.trim().isNotEmpty ||
      _district.text.trim().isNotEmpty ||
      _city.text.trim() != _initialCity.trim();

  /// Добавляет введённый зал (с валидацией формы); `true`, если добавлен.
  Future<bool> submit() async {
    if (!_formKey.currentState!.validate()) return false;
    final added = await context.read<GymsCubit>().add(
      name: _name.text,
      address: _address.text,
      city: _city.text,
      district: _district.text,
    );
    if (added) _reset();
    return added;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _add() => submit();

  Future<void> _useSuggestion(Gym gym) async {
    final added = await context.read<GymsCubit>().addSuggested(gym);
    if (added) _reset();
  }

  void _reset() {
    _name.clear();
    _address.clear();
    _district.clear();
    _formKey.currentState?.reset();
  }

  String? _required(String? value, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Обязательное поле';
    return text.length <= max ? null : 'Не более $max символов';
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<GymsCubit, GymsState>(
    builder: (context, state) => FyCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Залы, где я тренирую',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Ученики смогут найти вас по залу, району или адресу. '
              'Изменения сохраняются сразу.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (state.gyms.isEmpty)
              const FyInfoBanner(
                message: 'Залы пока не добавлены.',
                icon: Icons.fitness_center_rounded,
              )
            else
              for (final gym in state.gyms)
                ListTile(
                  key: ValueKey('gym-${gym.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    gym.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(gym.fullAddress),
                  trailing: IconButton(
                    tooltip: 'Убрать зал',
                    onPressed: state.saving
                        ? null
                        : () => context.read<GymsCubit>().remove(gym),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
            const Divider(height: 28),
            FyInputCard(
              label: 'Название зала',
              icon: Icons.fitness_center_rounded,
              controller: _name,
              validator: (value) => _required(value, 120),
              onChanged: (value) =>
                  context.read<GymsCubit>().suggest(value, city: _city.text),
            ),
            if (state.suggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Уже есть в базе — нажмите, чтобы выбрать:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final gym in state.suggestions)
                ListTile(
                  key: ValueKey('suggestion-${gym.id}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: Text(gym.name),
                  subtitle: Text(gym.fullAddress),
                  onTap: state.saving ? null : () => _useSuggestion(gym),
                ),
            ],
            const SizedBox(height: 10),
            FyInputCard(
              label: 'Точный адрес (улица, дом)',
              icon: Icons.place_outlined,
              controller: _address,
              validator: (value) => _required(value, 255),
            ),
            const SizedBox(height: 10),
            FyInputCard(
              label: 'Город',
              icon: Icons.location_city_outlined,
              controller: _city,
              validator: (value) => _required(value, 120),
            ),
            const SizedBox(height: 10),
            FyInputCard(
              label: 'Район (необязательно)',
              icon: Icons.map_outlined,
              controller: _district,
              validator: (value) => (value?.trim().length ?? 0) <= 120
                  ? null
                  : 'Не более 120 символов',
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              FyInfoBanner(
                message: state.error!,
                icon: Icons.error_outline_rounded,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.saving ? null : _add,
              icon: state.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Добавить зал'),
            ),
          ],
        ),
      ),
    ),
  );
}
