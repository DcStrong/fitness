import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fy_motion.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';

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
          bottomNavigationBar: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: NavigationBar(
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
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
                        destination.branchIndex == navigationShell.currentIndex,
                  );
                },
              ),
            ),
          ),
        );
      },
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

List<AppShellDestination> appShellDestinationsForRoles(Iterable<String> roles) {
  final isTrainer = roles.contains('trainer');

  if (!isTrainer && roles.contains('student')) {
    return const [
      AppShellDestination(
        branchIndex: 2,
        label: 'Тренеры',
        icon: Icons.person_search_outlined,
        selectedIcon: Icons.person_search,
        location: '/trainers',
      ),
      AppShellDestination(
        branchIndex: 1,
        label: 'Тренировки',
        icon: Icons.self_improvement_outlined,
        selectedIcon: Icons.self_improvement_rounded,
        location: '/sessions',
      ),
      AppShellDestination(
        branchIndex: 1,
        label: 'Мои заявки',
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note_rounded,
        location: '/booking-requests/mine',
        activePathPrefixes: ['/booking-requests'],
      ),
      AppShellDestination(
        branchIndex: 3,
        label: 'Профиль',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        location: '/profile',
      ),
    ];
  }

  return [
    const AppShellDestination(
      branchIndex: 0,
      label: 'Главная',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      location: '/home',
    ),
    const AppShellDestination(
      branchIndex: 1,
      label: 'Расписание',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      location: '/schedule',
    ),
    const AppShellDestination(
      branchIndex: 0,
      label: 'Тренировки',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      location: '/plans',
      activePathPrefixes: ['/plans', '/tags'],
    ),
    AppShellDestination(
      branchIndex: 2,
      label: isTrainer ? 'Ученики' : 'Тренер',
      icon: isTrainer ? Icons.groups_outlined : Icons.person_search_outlined,
      selectedIcon: isTrainer ? Icons.groups_rounded : Icons.person_search,
      location: isTrainer ? '/session-packages' : '/invite/accept',
    ),
    const AppShellDestination(
      branchIndex: 3,
      label: 'Профиль',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      location: '/profile',
    ),
  ];
}
