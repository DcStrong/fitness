import 'package:flutter/foundation.dart';

/// App-wide signal that schedule calendar data may be stale.
/// Call [notifyChanged] after mutations that affect sessions/slots/requests.
class ScheduleCalendarSync {
  final List<VoidCallback> _listeners = <VoidCallback>[];

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyChanged() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  void dispose() => _listeners.clear();
}
