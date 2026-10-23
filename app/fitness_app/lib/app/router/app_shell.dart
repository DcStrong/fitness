import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fy_card.dart';
import '../../core/widgets/fy_motion.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/chats/presentation/cubit/chat_unread_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final destinations = appShellDestinationsForRoles(
          state.user?.roles ?? const <String>[],
        );
        final selectedIndex = appShellSelectedIndex(
          destinations: destinations,
          currentBranchIndex: navigationShell.currentIndex,
          currentLocation: GoRouterState.of(context).matchedLocation,
        );

        return Scaffold(
          body: _ShellTabMotion(
            branchIndex: navigationShell.currentIndex,
            child: navigationShell,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.border),
                boxShadow: fyShadowLevel2,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: NavigationBar(
                  height: 64,
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: _DestinationIcon(
                          icon: destination.icon,
                          isChat:
                              destination.branchIndex == AppShellBranch.chats,
                        ),
                        selectedIcon: _DestinationIcon(
                          icon: destination.selectedIcon,
                          isChat:
                              destination.branchIndex == AppShellBranch.chats,
                        ),
                        label: destination.label,
                      ),
                  ],
                  onDestinationSelected: (index) {
                    final destination = destinations[index];
                    final location = destination.location;
                    if (location != null) {
                      context.go(location);
                      return;
                    }
                    navigationShell.goBranch(
                      destination.branchIndex,
                      initialLocation:
                          destination.branchIndex ==
                          navigationShell.currentIndex,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tab icon; the chat tab carries the unread counter.
class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.icon, required this.isChat});

  final IconData icon;
  final bool isChat;

  @override
  Widget build(BuildContext context) {
    if (!isChat) return Icon(icon);
    final unread = context.watch<ChatUnreadCubit>().state;
    return Badge(
      key: const Key('chat-tab-badge'),
      isLabelVisible: unread > 0,
      backgroundColor: AppColors.primary,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(icon),
    );
  }
}

/// Keeps [StatefulNavigationShell] mounted; fades/slides on branch change.
class _ShellTabMotion extends StatefulWidget {
  const _ShellTabMotion({required this.branchIndex, required this.child});

  final int branchIndex;
  final Widget child;

  @override
  State<_ShellTabMotion> createState() => _ShellTabMotionState();
}

class _ShellTabMotionState extends State<_ShellTabMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: FyMotion.tab,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.03, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _ShellTabMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchIndex == widget.branchIndex) return;
    if (fyReduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

@immutable
class AppShellDestination {
  const AppShellDestination({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.location,
    this.activePathPrefixes = const [],
  });

  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? location;
  final List<String> activePathPrefixes;

  bool matchesLocation(String currentLocation) {
    final target = location;
    if (target != null &&
        (currentLocation == target || currentLocation.startsWith('$target/'))) {
      return true;
    }
    return activePathPrefixes.any(
      (prefix) =>
          currentLocation == prefix || currentLocation.startsWith('$prefix/'),
    );
  }
}

int appShellSelectedIndex({
  required List<AppShellDestination> destinations,
  required int currentBranchIndex,
  required String currentLocation,
}) {
  final locationIndex = destinations.indexWhere(
    (destination) => destination.matchesLocation(currentLocation),
  );
  if (locationIndex >= 0) return locationIndex;

  final branchIndex = destinations.indexWhere(
    (destination) => destination.branchIndex == currentBranchIndex,
  );
  return branchIndex < 0 ? 0 : branchIndex;
}

/// Shell branches, in the order of [StatefulShellRoute] branches.
abstract final class AppShellBranch {
  static const home = 0;
  static const schedule = 1;
  static const students = 2;
  static const more = 3;
  static const chats = 4;
}

List<AppShellDestination> appShellDestinationsForRoles(Iterable<String> roles) {
  final isTrainer = roles.contains('trainer');

  if (!isTrainer && roles.contains('student')) {
    return const [
      AppShellDestination(
        branchIndex: AppShellBranch.home,
        label: 'Главная',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        location: '/home',
      ),
      AppShellDestination(
        branchIndex: AppShellBranch.schedule,
        label: 'Запись',
        icon: Icons.event_available_outlined,
        selectedIcon: Icons.event_available_rounded,
        location: '/schedule/book',
        activePathPrefixes: ['/booking-requests', '/trainers'],
      ),
      AppShellDestination(
        branchIndex: AppShellBranch.schedule,
        label: 'Тренировки',
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center_rounded,
        location: '/sessions',
        activePathPrefixes: ['/me/training'],
      ),
      AppShellDestination(
        branchIndex: AppShellBranch.chats,
        label: 'Чат',
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        location: '/chats',
      ),
      AppShellDestination(
        branchIndex: AppShellBranch.more,
        label: 'Профиль',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        location: '/profile',
        activePathPrefixes: ['/reviews'],
      ),
    ];
  }

  return const [
    AppShellDestination(
      branchIndex: AppShellBranch.home,
      label: 'Главная',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      location: '/home',
    ),
    AppShellDestination(
      branchIndex: AppShellBranch.schedule,
      label: 'Расписание',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      location: '/schedule',
      activePathPrefixes: ['/sessions', '/booking-requests'],
    ),
    AppShellDestination(
      branchIndex: AppShellBranch.students,
      label: 'Ученики',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      location: '/session-packages',
      activePathPrefixes: ['/students', '/invite'],
    ),
    AppShellDestination(
      branchIndex: AppShellBranch.chats,
      label: 'Чаты',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      location: '/chats',
    ),
    AppShellDestination(
      branchIndex: AppShellBranch.more,
      label: 'Ещё',
      icon: Icons.menu_rounded,
      selectedIcon: Icons.menu_open_rounded,
      location: '/more',
      activePathPrefixes: [
        '/plans',
        '/tags',
        '/finance',
        '/profile',
        '/reviews',
      ],
    ),
  ];
}
