import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../booking_requests/data/booking_requests_repository.dart';
import '../../session_packages/data/session_packages_repository.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import 'cubit/home_cubit.dart';
import 'home_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({this.now, super.key});

  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final isTrainer =
        context.read<AuthCubit>().state.user?.roles.contains('trainer') == true;
    return BlocProvider(
      create: (context) => HomeCubit(
        scheduleRepository: context.read<ScheduleRepository>(),
        bookingRequestsRepository: context.read<BookingRequestsRepository>(),
        sessionPackagesRepository: context.read<SessionPackagesRepository>(),
        isTrainer: isTrainer,
        now: now,
      )..load(),
      child: const HomeView(),
    );
  }
}
