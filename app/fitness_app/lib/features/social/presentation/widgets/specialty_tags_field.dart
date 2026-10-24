import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';

const maxSpecialtyTags = 8;
const maxSpecialtyLength = 30;

/// Ввод специализаций тегами-чипами: до [maxSpecialtyTags] тегов,
/// до [maxSpecialtyLength] символов в каждом.
class SpecialtyTagsField extends StatefulWidget {
  const SpecialtyTagsField({
    required this.tags,
    required this.onChanged,
    super.key,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<SpecialtyTagsField> createState() => SpecialtyTagsFieldState();
}

class SpecialtyTagsFieldState extends State<SpecialtyTagsField> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  late List<String> _tags = [...widget.tags];
  String? _error;

  bool get _full => _tags.length >= maxSpecialtyTags;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) commitPending();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Превращает недописанный текст в тег (вызывается и перед сохранением).
  void commitPending() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _add(text);
  }

  void _add(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty) return;
    if (_full) {
      setState(() => _error = 'Не более $maxSpecialtyTags специализаций');
      return;
    }
    if (_tags.any((item) => item.toLowerCase() == tag.toLowerCase())) {
      setState(() => _error = 'Такая специализация уже добавлена');
      _input.clear();
      return;
    }
    setState(() {
      _tags = [..._tags, tag];
      _error = null;
    });
    _input.clear();
    widget.onChanged(_tags);
  }

  void _remove(String tag) {
    setState(() {
      _tags = _tags.where((item) => item != tag).toList();
      _error = null;
    });
    widget.onChanged(_tags);
  }

  void _onTextChanged(String value) {
    if (!value.contains(',')) {
      if (_error != null) setState(() => _error = null);
      return;
    }
    final parts = value.split(',');
    _input.clear();
    for (final part in parts.take(parts.length - 1)) {
      _add(part);
    }
    _input.text = parts.last.trimLeft();
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _input,
          focusNode: _focus,
          enabled: !_full,
          inputFormatters: [
            LengthLimitingTextInputFormatter(maxSpecialtyLength),
          ],
          textInputAction: TextInputAction.done,
          onChanged: _onTextChanged,
          onSubmitted: (_) {
            commitPending();
            _focus.requestFocus();
          },
          decoration: InputDecoration(
            labelText: 'Специализации',
            hintText: _full
                ? 'Достигнут лимит тегов'
                : 'Введите и нажмите Enter или запятую',
            prefixIcon: const Icon(Icons.fitness_center_rounded),
            suffixIcon: IconButton(
              tooltip: 'Добавить специализацию',
              onPressed: _full ? null : commitPending,
              icon: const Icon(Icons.add_rounded),
            ),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_tags.length}/$maxSpecialtyTags тегов · '
          'до $maxSpecialtyLength символов в теге',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                InputChip(label: Text(tag), onDeleted: () => _remove(tag)),
            ],
          ),
        ],
      ],
    );
  }
}
