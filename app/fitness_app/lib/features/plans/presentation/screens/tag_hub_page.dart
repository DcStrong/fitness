import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../invitations/data/invitations_repository.dart';
import '../../data/plans_repository.dart';
import '../cubit/tag_hub_cubit.dart';
import 'tag_hub_view.dart';

class TagHubPage extends StatelessWidget {
  const TagHubPage({super.key, required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TagHubCubit(
        plans: context.read<PlansRepository>(),
        invitations: context.read<InvitationsRepository>(),
        tagId: tagId,
      )..load(),
      child: const TagHubView(),
    );
  }
}
