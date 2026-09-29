import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/fy_card.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../../social/presentation/widgets/social_profile_editor.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FyTopBar(title: 'Профиль'),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SocialProfileEditor(isTrainer: user.roles.contains('trainer')),
              const SizedBox(height: 28),
              Text(
                'Аккаунт',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              FyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Роли', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(user.roles.isEmpty ? '—' : user.roles.join(', ')),
                    const SizedBox(height: 16),
                    Text(
                      'Разрешения',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.permissions.isEmpty
                          ? '—'
                          : user.permissions.join('\n'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Выйти'),
              ),
            ],
          );
        },
      ),
    );
  }
}
