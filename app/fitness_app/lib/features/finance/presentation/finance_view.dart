import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_top_bar.dart';
import '../../../core/widgets/person_name_email.dart';
import '../data/finance_models.dart';
import '../data/money_formatter.dart';
import 'cubit/finance_cubit.dart';
import 'cubit/finance_state.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({required this.permissions, super.key});

  final List<String> permissions;

  bool _can(String permission) => permissions.contains(permission);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Финансы',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<FinanceCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _can('finance:record_expense')
          ? FloatingActionButton.extended(
              onPressed: () => _showExpenseDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.remove),
              label: const Text('Расход'),
            )
          : null,
      body: BlocConsumer<FinanceCubit, FinanceState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          if (state.status == FinanceStatus.loading && state.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == FinanceStatus.failure && state.summary == null) {
            return _Failure(error: state.error);
          }
          return RefreshIndicator(
            onRefresh: context.read<FinanceCubit>().load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _PeriodPicker(state: state),
                const SizedBox(height: 16),
                if (_can('finance:manage_settings'))
                  _SettingsCard(
                    settings: state.settings,
                    onEdit: () => _showSettingsDialog(context, state.settings),
                  ),
                if (_can('finance:manage_settings')) const SizedBox(height: 16),
                if (state.summary case final summary?)
                  _SummaryGrid(summary: summary),
                const SizedBox(height: 24),
                Text('Долги', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (state.debts.isEmpty)
                  const Text('Нет неоплаченных начислений')
                else
                  ...state.debts.map(
                    (debt) => _DebtTile(
                      debt: debt,
                      enabled:
                          _can('finance:mark_paid') && !state.actionInProgress,
                      onPay: () => _showPaymentDialog(context, debt),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Журнал',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    DropdownButton<String?>(
                      value: state.ledgerType,
                      hint: const Text('Все'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все')),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Доходы'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Расходы'),
                        ),
                        DropdownMenuItem(
                          value: 'adjustment',
                          child: Text('Корректировки'),
                        ),
                      ],
                      onChanged: (value) =>
                          context.read<FinanceCubit>().filterLedger(value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.ledger.isEmpty)
                  const Text('За период нет операций')
                else
                  ...state.ledger.map(
                    (entry) => _LedgerTile(
                      entry: entry,
                      canReverse:
                          _can('finance:adjust_own') &&
                          entry.reversesEntryId == null,
                      onReverse: () => _confirmReverse(context, entry),
                    ),
                  ),
                if (state.actionInProgress) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          );
        },
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
          FilledButton(
            onPressed: () => context.read<FinanceCubit>().load(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    ),
  );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.state});

  final FinanceState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in const [
          (FinancePeriod.day, 'День'),
          (FinancePeriod.week, 'Неделя'),
          (FinancePeriod.month, 'Месяц'),
        ])
          ChoiceChip(
            label: Text(item.$2),
            selected: state.period == item.$1,
            onSelected: (_) =>
                context.read<FinanceCubit>().selectPeriod(item.$1),
          ),
        ActionChip(
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(
            state.period == FinancePeriod.custom ? 'Свой период ✓' : 'Период',
          ),
          onPressed: () => _pickRange(context),
        ),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.settings, required this.onEdit});

  final FinanceSettings? settings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Цена тренировки'),
      subtitle: Text(
        settings == null
            ? 'Не настроена — новые записи недоступны'
            : MoneyFormatter.format(
                settings!.defaultSessionPriceMinor,
                currency: settings!.currency,
              ),
      ),
      trailing: TextButton(onPressed: onEdit, child: const Text('Изменить')),
    ),
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Начислено', summary.accruedMinor, Icons.trending_up),
      ('Получено', summary.receivedMinor, Icons.payments),
      ('Ожидается', summary.outstandingMinor, Icons.schedule),
      ('Расходы', summary.expensesMinor, Icons.trending_down),
      ('Корректировки', summary.adjustmentsMinor, Icons.swap_horiz),
      ('Чистый доход', summary.netMinor, Icons.account_balance_wallet),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$3, size: 20),
                      const SizedBox(height: 4),
                      Text(item.$1),
                      Text(
                        MoneyFormatter.format(
                          item.$2,
                          currency: summary.currency,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Проведено: ${summary.counts.completed} · '
          'Неявок к оплате: ${summary.counts.noShowChargeable} · '
          'Оплачено: ${summary.counts.paid} · '
          'Долгов: ${summary.counts.outstanding}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(
        personPrimaryLabel(
          displayName: debt.studentDisplayName,
          email: debt.studentEmail,
          fallback: debt.studentId ?? 'Ученик',
        ),
      ),
      subtitle: Text(
        [
          if (personEmailCaption(
                displayName: debt.studentDisplayName,
                email: debt.studentEmail,
              ) !=
              null)
            personEmailCaption(
              displayName: debt.studentDisplayName,
              email: debt.studentEmail,
            ),
          debt.earnedAt == null
              ? 'Начисление'
              : 'Начислено ${_date(debt.earnedAt!)}',
        ].whereType<String>().join(' · '),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            MoneyFormatter.format(debt.amountMinor, currency: debt.currency),
          ),
          InkWell(
            onTap: enabled ? onPay : null,
            child: Text(
              'Отметить оплату',
              style: TextStyle(
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
    final label = switch (entry.type) {
      'income' => 'Доход',
      'expense' => 'Расход',
      _ => 'Корректировка',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.type == 'income'
            ? Icons.add_circle_outline
            : entry.type == 'expense'
            ? Icons.remove_circle_outline
            : Icons.swap_horiz,
      ),
      title: Text(entry.category?.isNotEmpty == true ? entry.category! : label),
      subtitle: Text(
        [
          _date(entry.occurredAt),
          if (entry.note?.isNotEmpty == true) entry.note!,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            MoneyFormatter.format(entry.amountMinor, currency: entry.currency),
          ),
          if (canReverse)
            IconButton(
              tooltip: 'Обратная операция',
              onPressed: onReverse,
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
    );
  }
}

String _date(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return iso;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}
