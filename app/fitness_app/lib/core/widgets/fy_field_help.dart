import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'fy_bottom_sheet.dart';

/// Label row with optional help (question mark) showing Russian explanation.
class FyFieldHelpLabel extends StatelessWidget {
  const FyFieldHelpLabel({
    required this.text,
    this.helpTitle,
    this.helpBody,
    super.key,
  });

  final String text;
  final String? helpTitle;
  final String? helpBody;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
    );
    if (helpBody == null || helpBody!.isEmpty) {
      return Text(text, style: style);
    }

    return Row(
      children: [
        Flexible(child: Text(text, style: style)),
        const SizedBox(width: 4),
        IconButton(
          key: Key('field-help-${helpTitle ?? text}'),
          tooltip: helpTitle ?? 'Подсказка',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.help_outline_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
          onPressed: () => showFyFieldHelp(
            context,
            title: helpTitle ?? text,
            body: helpBody!,
          ),
        ),
      ],
    );
  }
}

Future<void> showFyFieldHelp(
  BuildContext context, {
  required String title,
  required String body,
}) {
  // Desktop/web: prefer dialog; touch-first platforms use bottom sheet.
  final useDialog =
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS ||
        TargetPlatform.windows ||
        TargetPlatform.linux => true,
        _ => false,
      };

  if (useDialog) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  return showFyBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ),
        ],
      ),
    ),
  );
}
