import 'dart:async';

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
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/chats/data/chat_realtime.dart';
import '../features/chats/data/chats_repository.dart';
import '../features/chats/presentation/cubit/chat_unread_cubit.dart';
import 'router/app_router.dart';
import 'router/invite_deep_links.dart';
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
  late final ChatsRepository _chatsRepository;
  late final ChatRealtime _chatRealtime;
  late final ChatUnreadCubit _chatUnreadCubit;
  StreamSubscription<AuthState>? _authSub;
  late final ScheduleCalendarSync _scheduleCalendarSync;
  late final ValueNotifier<ThemeMode> _themeMode;
  late final GoRouter _router;
  late final InviteDeepLinkListener _inviteDeepLinks;

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
    _chatsRepository = ChatsRepository(apiClient: apiClient);
    _chatRealtime = SocketChatRealtime(
      tokenStorage: _tokenStorage,
      refreshSession: _chatsRepository.unreadCount,
    );
    _chatUnreadCubit = ChatUnreadCubit(
      repository: _chatsRepository,
      realtime: _chatRealtime,
    );
    _scheduleCalendarSync = ScheduleCalendarSync();
    authCubit = AuthCubit(authRepository: _authRepository);
    _authCubit = authCubit;
    _themeMode = ValueNotifier(ThemeMode.light);
    _router = createAppRouter(
      _authCubit,
      _invitationsRepository,
      themeMode: _themeMode,
    );
    _inviteDeepLinks = InviteDeepLinkListener(_router)..start();
    // The chat socket lives exactly as long as the signed-in session.
    _authSub = _authCubit.stream.listen(_syncChat);
    _syncChat(_authCubit.state);
    _authCubit.bootstrap();
  }

  void _syncChat(AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      _chatUnreadCubit.start();
    } else {
      unawaited(_chatUnreadCubit.stop());
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _inviteDeepLinks.dispose();
    _chatUnreadCubit.close();
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
        RepositoryProvider.value(value: _chatsRepository),
        RepositoryProvider<ChatRealtime>.value(value: _chatRealtime),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider.value(value: _chatUnreadCubit),
        ],
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
