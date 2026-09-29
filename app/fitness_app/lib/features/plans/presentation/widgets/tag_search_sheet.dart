import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_button.dart';
import '../../../../core/widgets/fy_chip.dart';
import '../../data/plans_models.dart';

Future<Set<String>?> showTagSearchSheet(
  BuildContext context, {
  required List<TagItem> tags,
  required Set<String> selectedIds,
}) {
  return showFyBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TagSearchSheet(
      tags: tags,
      initialSelected: selectedIds,
    ),
  );
}

class _TagSearchSheet extends StatefulWidget {
  const _TagSearchSheet({
    required this.tags,
    required this.initialSelected,
  });

  final List<TagItem> tags;
  final Set<String> initialSelected;

  @override
  State<_TagSearchSheet> createState() => _TagSearchSheetState();
}

class _TagSearchSheetState extends State<_TagSearchSheet> {
  late final TextEditingController _query;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _selected = {...widget.initialSelected};
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<TagItem> get _visible {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return widget.tags;
    return [
      for (final tag in widget.tags)
        if (tag.name.toLowerCase().contains(needle)) tag,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final selectedTags = [
      for (final tag in widget.tags)
        if (_selected.contains(tag.id)) tag,
    ];
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Все ярлыки',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('library-tag-search'),
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Поиск тега',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (selectedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in selectedTags)
                    FyChip(
                      label: tag.name,
                      selected: true,
                      showCheckmark: false,
                      compact: true,
                      onSelected: (_) {
                        setState(() => _selected.remove(tag.id));
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final tag = visible[index];
                  final checked = _selected.contains(tag.id);
                  return CheckboxListTile(
                    key: Key('library-tag-option-${tag.id}'),
                    value: checked,
                    title: Text(tag.name),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            FyButton.primary(
              key: const Key('library-tag-apply'),
              label: 'Показать',
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}
