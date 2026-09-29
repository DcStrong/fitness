import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_bottom_sheet.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_secondary_button.dart';
import '../../../../core/widgets/person_name_email.dart';
import '../../data/session_package_models.dart';
import '../cubit/session_packages_cubit.dart';
import '../cubit/session_packages_state.dart';

Future<void> showPackageManageSheet(
  BuildContext context, {
  required StudentPackageRow row,
}) {
  return showFyBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<SessionPackagesCubit>(),
      child: _PackageManageSheet(row: row),
    ),
  );
}

class _PackageManageSheet extends StatefulWidget {
  const _PackageManageSheet({required this.row});

  final StudentPackageRow row;

  @override
  State<_PackageManageSheet> createState() => _PackageManageSheetState();
}

class _PackageManageSheetState extends State<_PackageManageSheet> {
  final _sessionsController = TextEditingController(text: '8');
  DateTime? _expiresAt;
  var _submitting = false;

  SessionPackage? get _package => widget.row.package;
  bool get _hasManageable => _package != null && !_package!.isArchived;

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() => _expiresAt = picked);
  }

  Future<void> _submitCreateOrExtend() async {
    final n = int.tryParse(_sessionsController.text.trim());
    if (n == null || n < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите число занятий больше 0')),
      );
      return;
    }
    setState(() => _submitting = true);
    final cubit = context.read<SessionPackagesCubit>();
    final ok =
        _hasManageable &&
            (_package!.isActive || _package!.isExhausted || _package!.isExpired)
        ? await cubit.extendPackage(
            packageId: _package!.id,
            addSessions: n,
            expiresAt: _expiresAt,
          )
        : await cubit.createPackage(
            studentId: widget.row.student.studentId,
            totalSessions: n,
            expiresAt: _expiresAt,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  Future<void> _archive() async {
    final pkg = _package;
    if (pkg == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('В архив?'),
        content: const Text(
          'Абонемент будет закрыт. Остаток заморозится; можно выдать новый.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('В архив'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _submitting = true);
    final ok = await context.read<SessionPackagesCubit>().archivePackage(
      pkg.id,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pkg = _package;
    final isExtend = pkg != null && !pkg.isArchived;
    final title = isExtend ? 'Продлить абонемент' : 'Выдать абонемент';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            PersonNameEmail(
              displayName: widget.row.student.studentDisplayName,
              email: widget.row.student.studentEmail,
              fallback: widget.row.student.studentId,
            ),
            if (pkg != null) ...[
              const SizedBox(height: 8),
              Text(
                '${pkg.remainingLabel} · всего ${pkg.totalSessions}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _sessionsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isExtend ? 'Добавить занятий' : 'Число занятий',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _expiresAt == null
                    ? 'Срок не задан'
                    : 'До ${_expiresAt!.day}.${_expiresAt!.month}.${_expiresAt!.year}',
              ),
              subtitle: const Text('Опциональный срок действия'),
              trailing: TextButton(
                onPressed: _submitting ? null : _pickExpiry,
                child: const Text('Выбрать'),
              ),
            ),
            const SizedBox(height: 8),
            FyPrimaryButton(
              label: isExtend ? 'Продлить' : 'Выдать',
              onPressed: _submitting ? null : _submitCreateOrExtend,
              isLoading: _submitting,
            ),
            if (pkg != null && !pkg.isArchived) ...[
              const SizedBox(height: 8),
              FySecondaryButton(
                label: 'В архив',
                onPressed: _submitting ? null : _archive,
              ),
            ],
            BlocBuilder<SessionPackagesCubit, SessionPackagesState>(
              builder: (context, state) {
                if (state.errorMessage == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
