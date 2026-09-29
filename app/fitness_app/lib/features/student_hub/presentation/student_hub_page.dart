import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../invitations/data/invitations_repository.dart';
import '../../plans/data/plans_repository.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../session_packages/data/session_packages_repository.dart';
import '../data/progress_repository.dart';
import 'cubit/student_hub_cubit.dart';
import 'student_hub_view.dart';

class StudentHubPage extends StatelessWidget {
  const StudentHubPage({
    super.key,
    required this.studentId,
    this.initialDisplayName,
  });

  final String studentId;
  final String? initialDisplayName;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    return BlocProvider(
      create: (context) => StudentHubCubit(
        studentId: studentId,
        viewerId: user?.id ?? '',
        isTrainer: user?.roles.contains('trainer') == true,
        schedule: context.read<ScheduleRepository>(),
        plans: context.read<PlansRepository>(),
        packages: context.read<SessionPackagesRepository>(),
        progress: context.read<ProgressRepository>(),
        invitations: context.read<InvitationsRepository>(),
        initialDisplayName: initialDisplayName,
      )..load(),
      child: const StudentHubView(),
    );
  }
}
