import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../plans/data/plans_repository.dart';
import '../../schedule/data/schedule_repository.dart';
import 'cubit/workout_program_cubit.dart';
import 'workout_program_view.dart';

class WorkoutProgramPage extends StatelessWidget {
  const WorkoutProgramPage({required this.recurringBookingId, super.key});

  final String recurringBookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkoutProgramCubit(
        recurringBookingId: recurringBookingId,
        schedule: context.read<ScheduleRepository>(),
        plans: context.read<PlansRepository>(),
      )..load(),
      child: const WorkoutProgramView(),
    );
  }
}
