import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_primary_button.dart';

class TagAttachOption {
  const TagAttachOption({required this.id, required this.label, this.subtitle});

  final String id;
  final String label;
  final String? subtitle;
}

Future<Set<String>?> showTagAttachSheet(
  BuildContext context, {
  required String title,
  required List<TagAttachOption> options,
  Set<String> attachedIds = const {},
}) {
  return showFyBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TagAttachSheet(
      title: title,
      options: options,
      attachedIds: attachedIds,
    ),
  );
}

class _TagAttachSheet extends StatefulWidget {
  const _TagAttachSheet({
    required this.title,
    required this.options,
    required this.attachedIds,
  });

  final String title;
  final List<TagAttachOption> options;
  final Set<String> attachedIds;

  @override
  State<_TagAttachSheet> createState() => _TagAttachSheetState();
}

class _TagAttachSheetState extends State<_TagAttachSheet> {
  final _query = TextEditingController();
  final _selected = <String>{};
  var _filter = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<TagAttachOption> get _visible {
    final needle = _filter.trim().toLowerCase();
    return [
      for (final option in widget.options)
        if (needle.isEmpty ||
            option.label.toLowerCase().contains(needle) ||
            (option.subtitle?.toLowerCase().contains(needle) ?? false))
          option,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tag-attach-search'),
            controller: _query,
            decoration: const InputDecoration(
              hintText: 'Поиск',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Нечего привязать',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final option = visible[index];
                      final attached = widget.attachedIds.contains(option.id);
                      final selected =
                          attached || _selected.contains(option.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        onChanged: attached
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selected.add(option.id);
                                  } else {
                                    _selected.remove(option.id);
                                  }
                                });
                              },
                        title: Text(option.label),
                        subtitle: option.subtitle == null
                            ? null
                            : Text(option.subtitle!),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          FyPrimaryButton(
            key: const Key('tag-attach-confirm'),
            label: 'Привязать',
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop(context, _selected),
          ),
        ],
      ),
    );
  }
}
