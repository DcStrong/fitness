import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../plans/data/plans_repository.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../session_packages/data/session_packages_repository.dart';
import 'cubit/session_workout_cubit.dart';
import 'session_workout_view.dart';

class SessionWorkoutPage extends StatelessWidget {
  const SessionWorkoutPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    return BlocProvider(
      create: (context) => SessionWorkoutCubit(
        sessionId: sessionId,
        viewerId: user?.id ?? '',
        permissions: user?.permissions ?? const [],
        schedule: context.read<ScheduleRepository>(),
        plans: context.read<PlansRepository>(),
        packages: context.read<SessionPackagesRepository>(),
      )..load(),
      child: const SessionWorkoutView(),
    );
  }
}
