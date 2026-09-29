import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/invitations_repository.dart';
import '../cubit/invite_create_cubit.dart';
import '../cubit/invite_create_state.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class InviteCreateScreen extends StatelessWidget {
  const InviteCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InviteCreateCubit(repository: context.read<InvitationsRepository>())
            ..create(),
      child: const _InviteCreateView(),
    );
  }
}

class _InviteCreateView extends StatelessWidget {
  const _InviteCreateView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Пригласить ученика',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: BlocBuilder<InviteCreateCubit, InviteCreateState>(
        builder: (context, state) {
          if (state.isLoading && state.invitation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitation = state.invitation;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Покажите QR ученику или скопируйте ссылку',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (invitation != null) ...[
                Center(
                  child: QrImageView(
                    data: invitation.inviteUrl,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  invitation.inviteUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: invitation.inviteUrl),
                    );
                    if (context.mounted) {
                      context.read<InviteCreateCubit>().markCopied();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ссылка скопирована')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(
                    state.copied ? 'Скопировано' : 'Копировать ссылку',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<InviteCreateCubit>().create(),
                  child: const Text('Создать новое'),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
