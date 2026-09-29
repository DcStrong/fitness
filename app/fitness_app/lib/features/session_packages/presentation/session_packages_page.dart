import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../booking_requests/data/booking_requests_repository.dart';
import '../../invitations/data/invitations_repository.dart';
import '../data/session_packages_repository.dart';
import 'cubit/session_packages_cubit.dart';
import 'session_packages_view.dart';

class SessionPackagesPage extends StatelessWidget {
  const SessionPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SessionPackagesCubit(
        packagesRepository: context.read<SessionPackagesRepository>(),
        invitationsRepository: context.read<InvitationsRepository>(),
        bookingRequestsRepository: context.read<BookingRequestsRepository>(),
      )..load(),
      child: const SessionPackagesView(),
    );
  }
}
