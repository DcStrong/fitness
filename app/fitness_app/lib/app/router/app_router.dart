import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/invite_links.dart';
import '../../core/devtools/dev_tools_overlay.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chats/presentation/chat_thread_page.dart';
import '../../features/chats/presentation/chats_page.dart';
import '../../features/finance/presentation/finance_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/invitations/data/invitations_repository.dart';
import '../../features/invitations/presentation/screens/invite_accept_screen.dart';
import '../../features/invitations/presentation/screens/invite_create_screen.dart';
import '../../features/more/presentation/more_page.dart';
import '../../features/plans/presentation/screens/plan_detail_screen.dart';
import '../../features/plans/presentation/screens/plan_edit_screen.dart';
import '../../features/plans/presentation/screens/plans_list_screen.dart';
import '../../features/plans/presentation/screens/tag_hub_page.dart';
import '../../features/plans/presentation/screens/tags_page.dart';
import '../../features/schedule/presentation/screens/coach_book_for_student_screen.dart';
import '../../features/schedule/presentation/screens/recurring_booking_create_page.dart';
import '../../features/schedule/presentation/screens/recurring_booking_detail_page.dart';
import '../../features/schedule/presentation/screens/recurring_bookings_list_page.dart';
import '../../features/schedule/presentation/screens/schedule_landing_screen.dart';
import '../../features/schedule/presentation/screens/session_history_screen.dart';
import '../../features/session_workout/presentation/session_workout_page.dart';
import '../../features/schedule/presentation/screens/sessions_list_screen.dart';
import '../../features/schedule/presentation/screens/student_book_screen.dart';
import '../../features/student_hub/presentation/student_hub_page.dart';
import '../../features/social/presentation/controller/unsaved_changes_guard.dart';
import '../../features/social/presentation/screens/portfolio_editor_screen.dart';
import '../../features/social/presentation/screens/reviews_screen.dart';
import '../../features/social/presentation/screens/trainer_profile_screen.dart';
import '../../features/social/presentation/screens/trainers_page.dart';
import '../../features/booking_requests/presentation/student_requests_page.dart';
import '../../features/booking_requests/presentation/trainer_inbox_page.dart';
import '../../features/booking_requests/presentation/booking_request_detail_page.dart';
import '../../features/booking_requests/data/booking_request_models.dart';
import '../../features/session_packages/presentation/session_packages_page.dart';
import '../../features/workout_program/presentation/workout_program_page.dart';
import 'app_route_observer.dart';
import 'app_shell.dart';

GoRouter createAppRouter(
  AuthCubit authCubit,
  InvitationsRepository invitationsRepository, {
  required ValueNotifier<ThemeMode> themeMode,
}) {
  // Защита от потери несохранённых изменений в формах профиля и портфолио.
  final profileGuard = UnsavedChangesGuard();
  final portfolioGuard = UnsavedChangesGuard();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) async {
      final status = authCubit.state.status;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isInviteAccept = loc == '/invite/accept';

      if (status == AuthStatus.unknown) {
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        if (isInviteAccept) {
          final token = InviteLinks.extractToken(
            state.uri.queryParameters['token'],
          );
          if (token != null) {
            await invitationsRepository.savePendingToken(token);
          }
          return '/login';
        }
        return isAuthRoute ? null : '/login';
      }

      if (status == AuthStatus.authenticated && isAuthRoute) {
        final pending = await invitationsRepository.readPendingToken();
        if (pending != null && pending.isNotEmpty) {
          return '/invite/accept?token=$pending';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            DevToolsOverlay(themeMode: themeMode, child: child),
        routes: [
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const RegisterScreen(),
            ),
          ),
          GoRoute(
            path: '/recurring/:id/program',
            redirect: (context, state) =>
                '/schedule/recurring/${state.pathParameters['id']}/program',
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                initialLocation: '/home',
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const HomePage(),
                  ),
                  GoRoute(
                    path: '/me/training',
                    builder: (context, state) => StudentHubPage(
                      studentId: authCubit.state.user?.id ?? '',
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                initialLocation: '/schedule',
                observers: [scheduleRouteObserver],
                routes: [
                  GoRoute(
                    path: '/schedule',
                    builder: (context, state) => const ScheduleLandingScreen(),
                  ),
                  GoRoute(
                    path: '/schedule/slots',
                    redirect: (context, state) => '/schedule',
                  ),
                  GoRoute(
                    path: '/schedule/book',
                    builder: (context, state) => const StudentBookScreen(),
                  ),
                  GoRoute(
                    path: '/schedule/book-for-student',
                    builder: (context, state) {
                      final extra = state.extra;
                      return CoachBookForStudentScreen(
                        prefill: extra is CoachBookPrefill ? extra : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/schedule/recurring',
                    builder: (context, state) =>
                        const RecurringBookingsListPage(),
                  ),
                  GoRoute(
                    path: '/schedule/recurring/create',
                    builder: (context, state) {
                      final extra = state.extra;
                      return RecurringBookingCreatePage(
                        prefill: extra is RecurringBookingPrefill
                            ? extra
                            : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/schedule/recurring/:id/program',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return WorkoutProgramPage(recurringBookingId: id);
                    },
                  ),
                  GoRoute(
                    path: '/schedule/recurring/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final extra = state.extra;
                      return RecurringBookingDetailPage(
                        id: id,
                        args: extra is RecurringBookingDetailArgs
                            ? extra
                            : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/sessions',
                    builder: (context, state) => const SessionsListScreen(),
                  ),
                  GoRoute(
                    path: '/sessions/:id/history',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SessionHistoryScreen(sessionId: id);
                    },
                  ),
                  GoRoute(
                    path: '/sessions/:id/plan-edit',
                    builder: (context, state) {
                      final id = state.uri.queryParameters['id'];
                      return PlanEditScreen(planId: id);
                    },
                  ),
                  GoRoute(
                    path: '/sessions/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SessionWorkoutPage(sessionId: id);
                    },
                  ),
                  GoRoute(
                    path: '/booking-requests/mine',
                    redirect: (context, state) => bookingRequestRoleRedirect(
                      authCubit.state.user?.roles ?? const [],
                      trainerRoute: false,
                    ),
                    builder: (context, state) => const StudentRequestsPage(),
                  ),
                  GoRoute(
                    path: '/booking-requests/inbox',
                    redirect: (context, state) => bookingRequestRoleRedirect(
                      authCubit.state.user?.roles ?? const [],
                      trainerRoute: true,
                    ),
                    builder: (context, state) => const TrainerInboxPage(),
                  ),
                  GoRoute(
                    path: '/booking-requests/:id',
                    builder: (context, state) => BookingRequestDetailPage(
                      request: state.extra is BookingRequest
                          ? state.extra! as BookingRequest
                          : null,
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                initialLocation: '/session-packages',
                routes: [
                  GoRoute(
                    path: '/trainers',
                    builder: (context, state) => const TrainersPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => TrainerProfileScreen(
                          trainerId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: '/invite',
                    builder: (context, state) => const InviteCreateScreen(),
                  ),
                  GoRoute(
                    path: '/session-packages',
                    builder: (context, state) => const SessionPackagesPage(),
                  ),
                  GoRoute(
                    path: '/students/:id',
                    builder: (context, state) {
                      final extra = state.extra;
                      final name = extra is String ? extra.trim() : '';
                      return StudentHubPage(
                        studentId: state.pathParameters['id']!,
                        initialDisplayName: name.isEmpty ? null : name,
                      );
                    },
                  ),
                  GoRoute(
                    path: '/invite/accept',
                    builder: (context, state) {
                      final fromQuery = state.uri.queryParameters['token'];
                      final token = InviteLinks.extractToken(fromQuery);
                      return InviteAcceptScreen(initialToken: token);
                    },
                  ),
                  GoRoute(
                    path: '/i/:token',
                    redirect: (context, state) {
                      final token = state.pathParameters['token'];
                      if (token == null || token.isEmpty) {
                        return '/invite/accept';
                      }
                      return '/invite/accept?token=$token';
                    },
                  ),
                ],
              ),
              StatefulShellBranch(
                initialLocation: '/more',
                routes: [
                  GoRoute(
                    path: '/more',
                    redirect: (context, state) =>
                        authCubit.state.user?.roles.contains('trainer') == true
                        ? null
                        : '/profile',
                    builder: (context, state) => const MorePage(),
                  ),
                  GoRoute(
                    path: '/finance',
                    redirect: (context, state) {
                      final permissions =
                          authCubit.state.user?.permissions ?? const <String>[];
                      return permissions.contains('finance:read_own')
                          ? null
                          : '/home';
                    },
                    builder: (context, state) => const FinancePage(),
                  ),
                  GoRoute(
                    path: '/tags',
                    builder: (context, state) => const TagsPage(),
                  ),
                  GoRoute(
                    path: '/tags/:id',
                    builder: (context, state) =>
                        TagHubPage(tagId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: '/plans',
                    builder: (context, state) {
                      final visible =
                          state.uri.queryParameters['visible'] == '1';
                      return PlansListScreen(visibleOnly: visible);
                    },
                  ),
                  GoRoute(
                    path: '/plans/edit',
                    builder: (context, state) {
                      final id = state.uri.queryParameters['id'];
                      return PlanEditScreen(planId: id);
                    },
                  ),
                  GoRoute(
                    path: '/plans/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PlanDetailScreen(planId: id);
                    },
                  ),
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) =>
                        ProfileScreen(guard: profileGuard),
                    onExit: (context, state) =>
                        profileGuard.confirmLeave(context),
                  ),
                  GoRoute(
                    path: '/profile/privacy',
                    builder: (context, state) =>
                        ProfileScreen(guard: profileGuard),
                    onExit: (context, state) =>
                        profileGuard.confirmLeave(context),
                  ),
                  GoRoute(
                    path: '/profile/portfolio/new',
                    builder: (context, state) =>
                        PortfolioEditorScreen(guard: portfolioGuard),
                    onExit: (context, state) =>
                        portfolioGuard.confirmLeave(context),
                  ),
                  GoRoute(
                    path: '/profile/portfolio/:id',
                    builder: (context, state) => PortfolioEditorScreen(
                      itemId: state.pathParameters['id'],
                      guard: portfolioGuard,
                    ),
                    onExit: (context, state) =>
                        portfolioGuard.confirmLeave(context),
                  ),
                  GoRoute(
                    path: '/reviews',
                    builder: (context, state) => ReviewsScreen(
                      isTrainer:
                          authCubit.state.user?.roles.contains('trainer') ==
                          true,
                    ),
                  ),
                  GoRoute(
                    path: '/reviews/new',
                    builder: (context, state) => ReviewEditorScreen(
                      sessionId: state.uri.queryParameters['sessionId'],
                    ),
                  ),
                  GoRoute(
                    path: '/reviews/:id/edit',
                    builder: (context, state) => ReviewEditorScreen(
                      reviewId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                initialLocation: '/chats',
                routes: [
                  GoRoute(
                    path: '/chats',
                    builder: (context, state) => ChatsPage(
                      isTrainer:
                          authCubit.state.user?.roles.contains('trainer') ==
                          true,
                    ),
                  ),
                  GoRoute(
                    path: '/chats/with/:userId',
                    builder: (context, state) => ChatThreadPage(
                      counterpartId: state.pathParameters['userId'],
                    ),
                  ),
                  GoRoute(
                    path: '/chats/:id',
                    builder: (context, state) => ChatThreadPage(
                      conversationId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? bookingRequestRoleRedirect(
  Iterable<String> roles, {
  required bool trainerRoute,
}) {
  final allowed = trainerRoute
      ? roles.contains('trainer')
      : roles.contains('student');
  return allowed ? null : '/home';
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
