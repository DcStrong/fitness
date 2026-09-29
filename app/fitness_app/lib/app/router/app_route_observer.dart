import 'package:flutter/material.dart';

/// Observes schedule-branch routes so calendar can refresh on [didPopNext].
final RouteObserver<ModalRoute<void>> scheduleRouteObserver =
    RouteObserver<ModalRoute<void>>();
