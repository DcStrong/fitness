import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../trainer_calendar_page.dart';
import 'sessions_list_screen.dart';
import 'student_book_screen.dart';

class ScheduleLandingScreen extends StatelessWidget {
  const ScheduleLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final roles = state.user?.roles ?? const <String>[];
        if (roles.contains('trainer')) {
          return const TrainerCalendarPage();
        }
        if (roles.contains('student')) {
          return const StudentBookScreen();
        }
        return const SessionsListScreen();
      },
    );
  }
}
