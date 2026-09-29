import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../data/finance_repository.dart';
import 'cubit/finance_cubit.dart';
import 'finance_view.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions =
        context.read<AuthCubit>().state.user?.permissions ?? const <String>[];
    return BlocProvider(
      create: (context) =>
          FinanceCubit(repository: context.read<FinanceRepository>())..load(),
      child: FinanceView(permissions: permissions),
    );
  }
}
