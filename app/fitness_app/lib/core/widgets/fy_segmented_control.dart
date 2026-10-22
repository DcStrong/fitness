import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class FySegment<T> {
  const FySegment({
    required this.value,
    required this.label,
    this.badgeCount,
    this.segmentKey,
  });

  final T value;
  final String label;
  final int? badgeCount;
  final Key? segmentKey;
}

/// Full-width segmented control, equal segments (library Мои / База / Упражнения).
///
/// DS v2: sunken track, the selected segment is a raised white tile.
class FySegmentedControl<T> extends StatelessWidget {
  const FySegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<FySegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: _SegmentTap(
                  key: segment.segmentKey,
                  selected: segment.value == value,
                  label: segment.label,
                  badgeCount: segment.badgeCount,
                  onTap: () {
                    if (segment.value != value) {
                      onChanged(segment.value);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTap extends StatelessWidget {
  const _SegmentTap({
    required this.selected,
    required this.label,
    required this.onTap,
    this.badgeCount,
    super.key,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final count = badgeCount ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowStrong,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  DecoratedBox(
                    key: const Key('schedule-requests-badge'),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
