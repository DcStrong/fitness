import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/schedule_models.dart';
import '../../data/schedule_repository.dart';
import '../schedule_format.dart';
import 'sessions_list_screen.dart';
import '../../../../core/widgets/fy_top_bar.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<SessionHistoryEvent> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<ScheduleRepository>().listSessionHistory(
        widget.sessionId,
      );
      if (!mounted) return;
      setState(() {
        _events = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FyTopBar(
        title: 'История тренировки',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sessions');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _events.isEmpty
          ? const Center(child: Text('Пока нет событий жизненного цикла'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = _events[index];
                final at = DateTime.parse(event.createdAt);
                final actor = event.actorEmail ?? event.actorUserId;
                final note = event.note?.trim();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${sessionStatusLabel(event.fromStatus)} → ${sessionStatusLabel(event.toStatus)}',
                  ),
                  subtitle: Text(
                    [
                      formatDateTime(at),
                      actor,
                      if (note != null && note.isNotEmpty) note,
                    ].join(' · '),
                  ),
                );
              },
            ),
    );
  }
}
