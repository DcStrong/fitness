import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/fy_segmented_control.dart';
import '../../../core/widgets/person_name_email.dart';
import '../../../core/widgets/widgets.dart';
import '../data/finance_models.dart';
import '../data/money_formatter.dart';
import 'cubit/finance_cubit.dart';
import 'cubit/finance_state.dart';

/// Finance (DS v2): period switch, a primary hero with money received, key
/// numbers, debts as cards and the ledger as quiet rows.
class FinanceView extends StatelessWidget {
  const FinanceView({required this.permissions, super.key});

  final List<String> permissions;

  bool _can(String permission) => permissions.contains(permission);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _can('finance:record_expense')
          ? FloatingActionButton.extended(
              onPressed: () => _showExpenseDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.remove_rounded),
              label: const Text('Расход'),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<FinanceCubit, FinanceState>(
          listenWhen: (previous, current) =>
              previous.error != current.error && current.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          },
          builder: (context, state) {
            final theme = Theme.of(context);
            final summary = state.summary;
            final Widget content;
            if (state.status == FinanceStatus.loading && summary == null) {
              content = const Center(child: CircularProgressIndicator());
            } else if (state.status == FinanceStatus.failure &&
                summary == null) {
              content = _Failure(error: state.error);
            } else {
              content = RefreshIndicator(
                onRefresh: context.read<FinanceCubit>().load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    96,
                  ),
                  children: [
                    _PeriodPicker(state: state),
                    const SizedBox(height: AppSpacing.md),
                    if (summary != null) ...[
                      _EarnedHero(summary: summary, period: state.period),
                      const SizedBox(height: AppSpacing.cardGap),
                      _StatGrid(summary: summary),
                      const SizedBox(height: AppSpacing.cardGap),
                      _TotalsCard(summary: summary),
                    ],
                    if (_can('finance:manage_settings')) ...[
                      const SizedBox(height: AppSpacing.cardGap),
                      _SettingsCard(
                        settings: state.settings,
                        onEdit: () =>
                            _showSettingsDialog(context, state.settings),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text('Должны оплатить', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.cardGap),
                    if (state.debts.isEmpty)
                      const _EmptyNote(text: 'Нет неоплаченных начислений')
                    else
                      for (final debt in state.debts) ...[
                        _DebtTile(
                          debt: debt,
                          enabled:
                              _can('finance:mark_paid') &&
                              !state.actionInProgress,
                          onPay: () => _showPaymentDialog(context, debt),
                        ),
                        const SizedBox(height: AppSpacing.cardGap),
                      ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Журнал',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        _LedgerFilter(
                          value: state.ledgerType,
                          onChanged: context.read<FinanceCubit>().filterLedger,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.ledger.isEmpty)
                      const _EmptyNote(text: 'За период нет операций')
                    else
                      for (final entry in state.ledger)
                        _LedgerTile(
                          entry: entry,
                          canReverse:
                              _can('finance:adjust_own') &&
                              entry.reversesEntryId == null,
                          onReverse: () => _confirmReverse(context, entry),
                        ),
                    if (state.actionInProgress) ...[
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      FySquareIconButton(
                        buttonKey: const Key('finance-back'),
                        tooltip: 'Назад',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => context.go('/more'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Финансы',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 20,
                            height: 26 / 20,
                          ),
                        ),
                      ),
                      FySquareIconButton(
                        tooltip: 'Обновить',
                        icon: Icons.refresh_rounded,
                        onPressed: () => context.read<FinanceCubit>().load(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog(
    BuildContext context,
    FinanceSettings? settings,
  ) async {
    final controller = TextEditingController(
      text: settings == null
          ? ''
          : _rublesInput(settings.defaultSessionPriceMinor),
    );
    final amount = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Цена тренировки'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Цена, ₽',
            hintText: '1500,00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              MoneyFormatter.parseRubles(controller.text),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || !context.mounted) return;
    await context.read<FinanceCubit>().saveSettings(amount);
  }

  Future<void> _showExpenseDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Добавить расход'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Сумма, ₽'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Категория (необязательно)',
              ),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final amount = MoneyFormatter.parseRubles(amountController.text);
              if (amount != null) {
                Navigator.pop(dialogContext, (
                  amount,
                  categoryController.text,
                  noteController.text,
                ));
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    amountController.dispose();
    categoryController.dispose();
    noteController.dispose();
    if (result == null || !context.mounted) return;
    await context.read<FinanceCubit>().addExpense(
      amountMinor: result.$1,
      category: result.$2.trim(),
      note: result.$3.trim(),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    FinanceDebt debt,
  ) async {
    var method = 'cash';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Отметить оплату'),
          content: DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(labelText: 'Способ оплаты'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Наличные')),
              DropdownMenuItem(value: 'transfer', child: Text('Перевод')),
              DropdownMenuItem(value: 'card', child: Text('Карта')),
              DropdownMenuItem(value: 'other', child: Text('Другое')),
            ],
            onChanged: (value) => setState(() => method = value ?? method),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, method),
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final success = await context.read<FinanceCubit>().markPaid(
      debt.chargeId,
      result,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Оплата отмечена')));
    }
  }

  Future<void> _confirmReverse(
    BuildContext context,
    FinanceLedgerEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Создать обратную операцию?'),
        content: const Text(
          'Запись останется в журнале. Будет добавлена корректировка.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<FinanceCubit>().reverse(entry.id);
    }
  }

  String _rublesInput(String amountMinor) {
    final value = amountMinor.padLeft(3, '0');
    return '${value.substring(0, value.length - 2)},'
        '${value.substring(value.length - 2)}';
  }
}

class _Failure extends StatelessWidget {
  const _Failure({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error ?? 'Не удалось загрузить финансы'),
          const SizedBox(height: 12),
          FyButton.secondary(
            label: 'Повторить',
            fullWidth: false,
            size: FyButtonSize.medium,
            onPressed: () => context.read<FinanceCubit>().load(),
          ),
        ],
      ),
    ),
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      FyCard(child: Text(text, style: Theme.of(context).textTheme.bodySmall));
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.state});

  final FinanceState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    final custom = state.period == FinancePeriod.custom;
    return Row(
      children: [
        Expanded(
          child: FySegmentedControl<FinancePeriod>(
            // A custom range selects nothing in the switch.
            value: state.period,
            segments: const [
              FySegment(value: FinancePeriod.day, label: 'День'),
              FySegment(value: FinancePeriod.week, label: 'Неделя'),
              FySegment(value: FinancePeriod.month, label: 'Месяц'),
              FySegment(value: FinancePeriod.custom, label: 'Период'),
            ],
            onChanged: (period) {
              if (period == FinancePeriod.custom) {
                _pickRange(context);
              } else {
                cubit.selectPeriod(period);
              }
            },
          ),
        ),
        if (custom) ...[
          const SizedBox(width: 8),
          FySquareIconButton(
            tooltip: 'Изменить период',
            icon: Icons.date_range_rounded,
            onPressed: () => _pickRange(context),
          ),
        ],
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final initialEnd = state.to.subtract(const Duration(days: 1));
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDateRange: DateTimeRange(start: state.from, end: initialEnd),
      helpText: 'Выберите период',
      saveText: 'Применить',
      cancelText: 'Отмена',
    );
    if (range != null && context.mounted) {
      await context.read<FinanceCubit>().selectCustomRange(
        range.start,
        range.end,
      );
    }
  }
}

class _EarnedHero extends StatelessWidget {
  const _EarnedHero({required this.summary, required this.period});

  final FinanceSummary summary;
  final FinancePeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (period) {
      FinancePeriod.day => 'Получено за день',
      FinancePeriod.week => 'Получено за неделю',
      FinancePeriod.month => 'Получено за месяц',
      FinancePeriod.custom => 'Получено за период',
    };
    return FyCard(
      color: AppColors.primary,
      border: null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onPrimaryMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            MoneyFormatter.format(
              summary.receivedMinor,
              currency: summary.currency,
            ),
            key: const Key('finance-received'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 32,
              height: 38 / 32,
              color: AppColors.onPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(
              label: 'Ждёт оплаты',
              value: MoneyFormatter.format(
                summary.outstandingMinor,
                currency: summary.currency,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.cardGap),
          Expanded(
            child: _Stat(
              label: 'Проведено',
              value:
                  '${summary.counts.completed} ${_sessionsWord(summary.counts.completed)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The remaining figures of the period as quiet rows in one card.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Начислено', summary.accruedMinor),
      ('Расходы', summary.expensesMinor),
      ('Корректировки', summary.adjustmentsMinor),
      ('Чистый доход', summary.netMinor),
    ];
    final theme = Theme.of(context);
    return FyCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.$1, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    MoneyFormatter.format(row.$2, currency: summary.currency),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.settings, required this.onEdit});

  final FinanceSettings? settings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FyCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const FyIconBadge(icon: Icons.tune_rounded, size: 40, iconSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Цена тренировки', style: theme.textTheme.titleMedium),
                Text(
                  settings == null
                      ? 'Не настроена — новые записи недоступны'
                      : MoneyFormatter.format(
                          settings!.defaultSessionPriceMinor,
                          currency: settings!.currency,
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.enabled,
    required this.onPay,
  });

  final FinanceDebt debt;
  final bool enabled;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = personPrimaryLabel(
      displayName: debt.studentDisplayName,
      email: debt.studentEmail,
      fallback: debt.studentId ?? 'Ученик',
    );
    final email = personEmailCaption(
      displayName: debt.studentDisplayName,
      email: debt.studentEmail,
    );
    final sub = [
      ?email,
      debt.earnedAt == null
          ? 'Начисление'
          : 'Начислено ${_date(debt.earnedAt!)}',
    ].join(' · ');
    return FyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FyAvatar(
                displayName: debt.studentDisplayName,
                email: debt.studentEmail,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MoneyFormatter.format(
                  debt.amountMinor,
                  currency: debt.currency,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: FyStatusChip(status: FyStatus.waiting, label: 'Ждёт оплаты'),
          ),
          const SizedBox(height: 10),
          FyButton.soft(
            key: Key('finance-pay-${debt.chargeId}'),
            label: 'Отметить оплату',
            icon: Icons.check_rounded,
            size: FyButtonSize.medium,
            onPressed: enabled ? onPay : null,
          ),
        ],
      ),
    );
  }
}

class _LedgerFilter extends StatelessWidget {
  const _LedgerFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: value,
        hint: const Text('Все'),
        borderRadius: BorderRadius.circular(AppRadii.control),
        icon: const Icon(Icons.expand_more_rounded),
        items: const [
          DropdownMenuItem(value: null, child: Text('Все')),
          DropdownMenuItem(value: 'income', child: Text('Доходы')),
          DropdownMenuItem(value: 'expense', child: Text('Расходы')),
          DropdownMenuItem(value: 'adjustment', child: Text('Корректировки')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.entry,
    required this.canReverse,
    required this.onReverse,
  });

  final FinanceLedgerEntry entry;
  final bool canReverse;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (entry.type) {
      'income' => 'Доход',
      'expense' => 'Расход',
      _ => 'Корректировка',
    };
    final icon = switch (entry.type) {
      'income' => Icons.south_west_rounded,
      'expense' => Icons.north_east_rounded,
      _ => Icons.swap_horiz_rounded,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          FyIconBadge(icon: icon, size: 36, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.category?.isNotEmpty == true ? entry.category! : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                Text(
                  [
                    _date(entry.occurredAt),
                    if (entry.note?.isNotEmpty == true) entry.note!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            MoneyFormatter.format(entry.amountMinor, currency: entry.currency),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (canReverse)
            IconButton(
              tooltip: 'Обратная операция',
              onPressed: onReverse,
              icon: const Icon(Icons.undo_rounded),
            ),
        ],
      ),
    );
  }
}

String _sessionsWord(int count) {
  final mod100 = count % 100;
  final mod10 = count % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'занятий';
  if (mod10 == 1) return 'занятие';
  if (mod10 >= 2 && mod10 <= 4) return 'занятия';
  return 'занятий';
}

String _date(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}
