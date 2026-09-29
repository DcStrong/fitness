import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../features/finance/data/finance_repository.dart';
import '../features/invitations/data/invitations_repository.dart';
import '../features/plans/data/plans_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/schedule/data/schedule_repository.dart';
import '../features/schedule/presentation/schedule_calendar_sync.dart';
import '../features/session_packages/data/session_packages_repository.dart';
import '../features/student_hub/data/progress_repository.dart';
import '../features/social/data/social_repository.dart';
import '../features/booking_requests/data/booking_requests_repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FitnessApp extends StatefulWidget {
  const FitnessApp({super.key});

  @override
  State<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends State<FitnessApp> {
  late final TokenStorage _tokenStorage;
  late final AuthCubit _authCubit;
  late final AuthRepository _authRepository;
  late final InvitationsRepository _invitationsRepository;
  late final ScheduleRepository _scheduleRepository;
  late final PlansRepository _plansRepository;
  late final FinanceRepository _financeRepository;
  late final SocialRepository _socialRepository;
  late final BookingRequestsRepository _bookingRequestsRepository;
  late final SessionPackagesRepository _sessionPackagesRepository;
  late final ProgressRepository _progressRepository;
  late final ScheduleCalendarSync _scheduleCalendarSync;
  late final ValueNotifier<ThemeMode> _themeMode;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    late final AuthCubit authCubit;
    final apiClient = ApiClient(
      tokenStorage: _tokenStorage,
      onSessionExpired: () => authCubit.onSessionExpired(),
    );
    _authRepository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: _tokenStorage,
    );
    _invitationsRepository = InvitationsRepository(apiClient: apiClient);
    _scheduleRepository = ScheduleRepository(apiClient: apiClient);
    _plansRepository = PlansRepository(apiClient: apiClient);
    _financeRepository = FinanceRepository(apiClient: apiClient);
    _socialRepository = SocialRepository(apiClient: apiClient);
    _bookingRequestsRepository = BookingRequestsRepository(
      apiClient: apiClient,
    );
    _sessionPackagesRepository = SessionPackagesRepository(
      apiClient: apiClient,
    );
    _progressRepository = ProgressRepository(apiClient: apiClient);
    _scheduleCalendarSync = ScheduleCalendarSync();
    authCubit = AuthCubit(authRepository: _authRepository);
    _authCubit = authCubit;
    _themeMode = ValueNotifier(ThemeMode.light);
    _router = createAppRouter(
      _authCubit,
      _invitationsRepository,
      themeMode: _themeMode,
    );
    _authCubit.bootstrap();
  }

  @override
  void dispose() {
    _authCubit.close();
    _router.dispose();
    _themeMode.dispose();
    _scheduleCalendarSync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _invitationsRepository),
        RepositoryProvider.value(value: _scheduleRepository),
        RepositoryProvider.value(value: _plansRepository),
        RepositoryProvider.value(value: _financeRepository),
        RepositoryProvider.value(value: _socialRepository),
        RepositoryProvider.value(value: _bookingRequestsRepository),
        RepositoryProvider.value(value: _sessionPackagesRepository),
        RepositoryProvider.value(value: _progressRepository),
        RepositoryProvider.value(value: _scheduleCalendarSync),
      ],
      child: BlocProvider.value(
        value: _authCubit,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeMode,
          builder: (context, themeMode, _) => MaterialApp.router(
            title: 'Fitness Yoda',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            themeAnimationDuration: Duration.zero,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
