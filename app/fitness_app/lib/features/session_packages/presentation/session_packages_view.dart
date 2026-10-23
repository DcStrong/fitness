import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../core/widgets/fy_avatar.dart';
import '../../../core/widgets/fy_button.dart';
import '../../../core/widgets/fy_card.dart';
import '../../../core/widgets/fy_chip.dart';
import '../../../core/widgets/fy_info_banner.dart';
import '../../../core/widgets/fy_secondary_button.dart';
import '../../../core/widgets/fy_status_chip.dart';
import '../../../core/widgets/person_name_email.dart';
import 'cubit/session_packages_cubit.dart';
import 'cubit/session_packages_state.dart';
import 'widgets/package_manage_sheet.dart';

class SessionPackagesView extends StatefulWidget {
  const SessionPackagesView({super.key});

  @override
  State<SessionPackagesView> createState() => _SessionPackagesViewState();
}

class _SessionPackagesViewState extends State<SessionPackagesView> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(StudentPackageRow row) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final name = row.student.studentDisplayName?.toLowerCase() ?? '';
    final email = row.student.studentEmail?.toLowerCase() ?? '';
    return name.contains(needle) || email.contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SessionPackagesCubit, SessionPackagesState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SessionPackagesState state) {
    if (state.status == SessionPackagesStatus.loading ||
        state.status == SessionPackagesStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == SessionPackagesStatus.failure) {
      return Padding(
        padding: const EdgeInsets.all(20),
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
              onPressed: () => context.read<SessionPackagesCubit>().load(),
            ),
          ],
        ),
      );
    }
    if (state.rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: FyCard(
          child: FyInfoBanner(
            message: 'Пока нет связанных учеников. Пригласите ученика по QR.',
            icon: Icons.groups_outlined,
          ),
        ),
      );
    }

    final visible = state.visibleRows.where(_matches).toList();
    return RefreshIndicator(
      onRefresh: context.read<SessionPackagesCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            key: const Key('students-search'),
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Имя или почта',
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16, right: 10),
                child: Icon(Icons.search_rounded, size: 22),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 48),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in StudentListFilter.values) ...[
                  if (filter != StudentListFilter.all) const SizedBox(width: 8),
                  FyChip(
                    key: Key('students-filter-${filter.name}'),
                    label: _filterLabel(filter),
                    selected: state.filter == filter,
                    showCheckmark: false,
                    onSelected: (_) =>
                        context.read<SessionPackagesCubit>().setFilter(filter),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const FyCard(
              child: FyInfoBanner(
                message: 'Нет учеников по этому запросу.',
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
  }

  String _filterLabel(StudentListFilter filter) => switch (filter) {
    StudentListFilter.all => 'Все',
    StudentListFilter.paid => 'Оплачен',
    StudentListFilter.unpaid => 'Не оплачен',
    StudentListFilter.waiting => 'Ожидает',
  };
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Ученики',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(width: 8),
          FyButton.primary(
            key: const Key('students-invite'),
            label: 'Пригласить',
            icon: Icons.qr_code_2_rounded,
            size: FyButtonSize.medium,
            fullWidth: false,
            onPressed: () => context.push('/invite'),
          ),
        ],
      ),
    );
  }
}

class _StudentRowCard extends StatelessWidget {
  const _StudentRowCard({required this.row});

  final StudentPackageRow row;

  @override
  Widget build(BuildContext context) {
    final student = row.student;
    final name = personPrimaryLabel(
      displayName: student.studentDisplayName,
      email: student.studentEmail,
      fallback: student.studentId,
    );
    final caption = personEmailCaption(
      displayName: student.studentDisplayName,
      email: student.studentEmail,
    );
    return FyCard(
      key: Key('package-row-${student.studentId}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/students/${student.studentId}', extra: name),
      child: Row(
        children: [
          FyAvatar(
            displayName: student.studentDisplayName,
            email: student.studentEmail,
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
                  style: const TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // The package state doubles as the entry to package management.
          InkWell(
            key: Key('package-manage-${student.studentId}'),
            borderRadius: BorderRadius.circular(AppRadii.control),
            onTap: () => showPackageManageSheet(context, row: row),
            child: _PackageChip(row: row),
          ),
        ],
      ),
    );
  }
}

class _PackageChip extends StatelessWidget {
  const _PackageChip({required this.row});

  final StudentPackageRow row;

  @override
  Widget build(BuildContext context) {
    final pkg = row.package;
    if (row.category == StudentPaymentCategory.waiting) {
      return const FyStatusChip(status: FyStatus.waiting, label: 'Ожидает');
    }
    if (pkg == null) {
      return const FyStatusChip(
        status: FyStatus.cancelled,
        label: 'Нет пакета',
      );
    }
    if (pkg.isExhausted || pkg.isExpired) {
      return FyStatusChip(status: FyStatus.noShow, label: pkg.remainingLabel);
    }
    if (pkg.isActive) {
      return FyStatusChip(
        status: FyStatus.confirmed,
        label: pkg.remainingLabel,
      );
    }
    return FyStatusChip(status: FyStatus.cancelled, label: pkg.remainingLabel);
  }
}
