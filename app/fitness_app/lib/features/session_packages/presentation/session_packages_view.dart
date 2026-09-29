import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_chip.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_secondary_button.dart';
import '../../../core/widgets/fy_top_bar.dart';
import '../../../core/widgets/person_name_email.dart';
import 'cubit/session_packages_cubit.dart';
import 'cubit/session_packages_state.dart';
import 'widgets/package_manage_sheet.dart';

class SessionPackagesView extends StatelessWidget {
  const SessionPackagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Ученики и абонементы',
        actions: [
          IconButton(
            tooltip: 'Пригласить',
            onPressed: () => context.push('/invite'),
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
        ],
      ),
      body: BlocBuilder<SessionPackagesCubit, SessionPackagesState>(
        builder: (context, state) {
          if (state.status == SessionPackagesStatus.loading ||
              state.status == SessionPackagesStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SessionPackagesStatus.failure) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FyCard(
                    child: FyInfoBanner(
                      message: state.errorMessage ?? 'Не удалось загрузить',
                      icon: Icons.sync_problem_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FySecondaryButton(
                    label: 'Повторить',
                    onPressed: () =>
                        context.read<SessionPackagesCubit>().load(),
                  ),
                ],
              ),
            );
          }
          if (state.rows.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FyCard(
                    child: FyInfoBanner(
                      message:
                          'Пока нет связанных учеников. Пригласите ученика по QR.',
                      icon: Icons.groups_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FySecondaryButton(
                    label: 'Пригласить',
                    onPressed: () => context.push('/invite'),
                  ),
                ],
              ),
            );
          }

          final visible = state.visibleRows;
          return RefreshIndicator(
            onRefresh: context.read<SessionPackagesCubit>().load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in StudentListFilter.values)
                      FyChip(
                        key: Key('students-filter-${filter.name}'),
                        label: _filterLabel(filter),
                        selected: state.filter == filter,
                        showCheckmark: false,
                        compact: true,
                        onSelected: (_) => context
                            .read<SessionPackagesCubit>()
                            .setFilter(filter),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  const FyCard(
                    child: FyInfoBanner(
                      message: 'Нет учеников в этом фильтре.',
                      icon: Icons.filter_alt_outlined,
                    ),
                  )
                else
                  for (var index = 0; index < visible.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _StudentRowCard(row: visible[index]),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _filterLabel(StudentListFilter filter) => switch (filter) {
    StudentListFilter.all => 'Все',
    StudentListFilter.paid => 'Оплачен',
    StudentListFilter.unpaid => 'Не оплачен',
    StudentListFilter.waiting => 'Ожидает',
  };
}

class _StudentRowCard extends StatelessWidget {
  const _StudentRowCard({required this.row});

  final StudentPackageRow row;

  @override
  Widget build(BuildContext context) {
    final pkg = row.package;
    final subtitle = switch (row.category) {
      StudentPaymentCategory.waiting => 'Ожидает решения по заявке',
      StudentPaymentCategory.paid => pkg?.remainingLabel ?? 'Активный пакет',
      StudentPaymentCategory.unpaid =>
        pkg == null ? 'Нет пакета' : pkg.remainingLabel,
    };
    return FyCard(
      key: Key('package-row-${row.student.studentId}'),
      onTap: () => context.push(
        '/students/${row.student.studentId}',
        extra: row.student.studentLabel,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonNameEmail(
                  displayName: row.student.studentDisplayName,
                  email: row.student.studentEmail,
                  fallback: row.student.studentId,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        row.category == StudentPaymentCategory.waiting ||
                            pkg?.isExhausted == true ||
                            pkg?.isExpired == true
                        ? Theme.of(context).colorScheme.error
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('package-manage-${row.student.studentId}'),
            tooltip: 'Абонемент',
            onPressed: () => showPackageManageSheet(context, row: row),
            icon: const Icon(Icons.card_membership_outlined),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
