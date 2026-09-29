import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import 'dev_accounts.dart';

/// Debug overlay drawn above [child]. Must live **under** [Overlay]
/// (e.g. inside a [ShellRoute]), not in [MaterialApp.builder].
///
/// Important: do not use full-size [Align] for the handle — on web it
/// expands to the whole screen and breaks mouse hit-testing.
class DevToolsOverlay extends StatefulWidget {
  const DevToolsOverlay({
    super.key,
    required this.themeMode,
    required this.child,
  });

  final ValueNotifier<ThemeMode> themeMode;
  final Widget child;

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  static const double _panelWidth = 280;
  static const double _handleWidth = 28;
  static const double _handleHeight = 72;

  bool _open = false;
  bool _busy = false;
  String? _status;

  void _setDarkMode(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Let the SwitchListTile finish its current Ink response before rebuilding
    // MaterialApp. Rebuilding synchronously can attach the same ink renderer
    // GlobalKey to both the outgoing and incoming themed trees.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.themeMode.value != mode) {
        widget.themeMode.value = mode;
      }
    });
  }

  Future<void> _goAndWait(String location) async {
    final router = GoRouter.of(context);
    final expectedPath = Uri.parse(location).path;
    final routeReached = Completer<void>();

    void checkLocation() {
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath == expectedPath && !routeReached.isCompleted) {
        routeReached.complete();
      }
    }

    router.routerDelegate.addListener(checkLocation);
    try {
      context.go(location);
      checkLocation();
      await routeReached.future;
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      router.routerDelegate.removeListener(checkLocation);
    }
  }

  Future<void> _loginAs(DevAccount account) async {
    final cubit = context.read<AuthCubit>();
    setState(() {
      _busy = true;
      _status = 'Вход: ${account.email}…';
    });
    try {
      if (cubit.state.status == AuthStatus.authenticated) {
        await cubit.logout();
        if (!mounted) return;
        await _goAndWait('/login');
        if (!mounted) return;
      }
      await cubit.login(email: account.email, password: account.password);
      if (!mounted) return;
      final err = cubit.state.errorMessage;
      if (err == null) {
        await _goAndWait(
          account.roleLabel == 'student' ? '/trainers' : '/home',
        );
        if (!mounted) return;
      }
      setState(() {
        _busy = false;
        _status = err ?? 'Вошли как ${account.label}';
        if (err == null) _open = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return widget.child;
    }

    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final handleTop = (screenHeight - _handleHeight) / 2;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: widget.child),
        if (_open) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _busy ? null : () => setState(() => _open = false),
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: _panelWidth,
            child: Material(
              elevation: 8,
              color: scheme.surfaceContainerHigh,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'DevTools',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Скрыть',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _open = false),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      Text(
                        'Тема',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: widget.themeMode,
                        builder: (context, mode, _) {
                          final isDark = mode == ThemeMode.dark;
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                            ),
                            title: Text(isDark ? 'Тёмная' : 'Светлая'),
                            value: isDark,
                            onChanged: _setDarkMode,
                          );
                        },
                      ),
                      const Divider(),
                      Text(
                        'Быстрый вход',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final email = state.user?.email;
                          return Text(
                            email == null
                                ? 'Сейчас: не авторизован'
                                : 'Сейчас: $email',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ...DevAccounts.all.map((account) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FilledButton.tonal(
                            key: ValueKey(
                              'devtools-login-${account.roleLabel}',
                            ),
                            onPressed: _busy ? null : () => _loginAs(account),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1,
                              heightFactor: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(account.label),
                                  Text(
                                    account.email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_busy) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      if (_status != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _status!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        'Только debug-сборка',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        Positioned(
          right: _open ? _panelWidth : 0,
          top: handleTop,
          width: _handleWidth,
          height: _handleHeight,
          child: Material(
            elevation: 4,
            color: scheme.primaryContainer,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: InkWell(
              key: const ValueKey('devtools-handle'),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              onTap: _busy ? null : () => setState(() => _open = !_open),
              child: Icon(
                _open ? Icons.chevron_right : Icons.chevron_left,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
