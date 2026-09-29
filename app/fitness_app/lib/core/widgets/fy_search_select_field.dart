import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'fy_bottom_sheet.dart';

/// One option in [FySearchSelectField].
class FySearchSelectOption<T> {
  const FySearchSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.searchText,
  });

  final T value;
  final String label;
  final String? subtitle;

  /// Extra text used only for filtering (e.g. email).
  final String? searchText;

  String get haystack =>
      '${label.toLowerCase()} ${(subtitle ?? '').toLowerCase()} '
      '${(searchText ?? '').toLowerCase()}';
}

/// Tappable field that opens a searchable bottom-sheet list.
class FySearchSelectField<T> extends StatelessWidget {
  const FySearchSelectField({
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hintText = 'Выберите',
    this.searchHintText = 'Поиск',
    this.sheetTitle,
    this.emptyText = 'Ничего не найдено',
    this.fieldKey,
    super.key,
  });

  final String label;
  final T? value;
  final List<FySearchSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String hintText;
  final String searchHintText;
  final String? sheetTitle;
  final String emptyText;
  final Key? fieldKey;

  FySearchSelectOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showFyBottomSheet<T>(
      context: context,
      builder: (context) => _FySearchSelectSheet<T>(
        title: sheetTitle ?? label,
        options: options,
        selected: value,
        searchHintText: searchHintText,
        emptyText: emptyText,
      ),
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: fieldKey,
            borderRadius: BorderRadius.circular(14),
            onTap: options.isEmpty ? null : () => _open(context),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: selected == null
                          ? Text(
                              hintText,
                              style: TextStyle(color: AppColors.textMuted),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (selected.subtitle != null &&
                                    selected.subtitle!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      selected.subtitle!,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.iconInactive,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FySearchSelectSheet<T> extends StatefulWidget {
  const _FySearchSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchHintText,
    required this.emptyText,
  });

  final String title;
  final List<FySearchSelectOption<T>> options;
  final T? selected;
  final String searchHintText;
  final String emptyText;

  @override
  State<_FySearchSelectSheet<T>> createState() =>
      _FySearchSelectSheetState<T>();
}

class _FySearchSelectSheetState<T> extends State<_FySearchSelectSheet<T>> {
  final _query = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<FySearchSelectOption<T>> get _filtered {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((option) => option.haystack.contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              key: const Key('fy-search-select-query'),
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHintText,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.mintSoft.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        widget.emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.value == widget.selected;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              option.subtitle == null ||
                                  option.subtitle!.trim().isEmpty
                              ? null
                              : Text(option.subtitle!),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
