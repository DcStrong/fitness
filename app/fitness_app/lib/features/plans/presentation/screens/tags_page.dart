import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/plans_repository.dart';
import '../cubit/tags_cubit.dart';
import 'tags_view.dart';

class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TagsCubit(plans: context.read<PlansRepository>())..load(),
      child: const TagsView(),
    );
  }
}
