import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/invitations_repository.dart';
import '../cubit/invite_accept_cubit.dart';
import '../cubit/invite_accept_state.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class InviteAcceptScreen extends StatelessWidget {
  const InviteAcceptScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = InviteAcceptCubit(
          repository: context.read<InvitationsRepository>(),
          initialToken: initialToken,
        );
        cubit.loadPendingIfEmpty();
        return cubit;
      },
      child: const _InviteAcceptView(),
    );
  }
}

class _InviteAcceptView extends StatefulWidget {
  const _InviteAcceptView();

  @override
  State<_InviteAcceptView> createState() => _InviteAcceptViewState();
}

class _InviteAcceptViewState extends State<_InviteAcceptView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final token = context.read<InviteAcceptCubit>().state.token;
    _controller = TextEditingController(text: token);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<InviteAcceptCubit>().accept();
    if (ok && mounted) {
      final email = context.read<InviteAcceptCubit>().state.result?.coachEmail;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email == null
                ? 'Приглашение принято'
                : 'Вы связаны с тренером $email',
          ),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'Принять приглашение',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: BlocConsumer<InviteAcceptCubit, InviteAcceptState>(
        listenWhen: (prev, next) =>
            prev.token != next.token && next.token.isNotEmpty,
        listener: (context, state) {
          if (_controller.text != state.token) {
            _controller.text = state.token;
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Вставьте ссылку или токен от тренера',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Ссылка или токен',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: context.read<InviteAcceptCubit>().setTokenInput,
                  minLines: 1,
                  maxLines: 3,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Принять'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
