import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../schedule/data/schedule_repository.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../../session_packages/data/session_packages_repository.dart';
import '../../domain/home_schedule.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required ScheduleRepository scheduleRepository,
    DateTime Function()? now,
    Duration tickInterval = const Duration(minutes: 1),
    bool enableTicker = true,
    BookingRequestsRepository? bookingRequestsRepository,
    SessionPackagesRepository? sessionPackagesRepository,
    bool isTrainer = false,
  }) : _scheduleRepository = scheduleRepository,
       _bookingRequestsRepository = bookingRequestsRepository,
       _sessionPackagesRepository = sessionPackagesRepository,
       _isTrainer = isTrainer,
       _now = now ?? DateTime.now,
       super(const HomeState()) {
    if (enableTicker) {
      _ticker = Timer.periodic(tickInterval, (_) => unawaited(tick()));
    }
  }

  final ScheduleRepository _scheduleRepository;
  final BookingRequestsRepository? _bookingRequestsRepository;
  final SessionPackagesRepository? _sessionPackagesRepository;
  final bool _isTrainer;
  final DateTime Function() _now;
  Timer? _ticker;
  bool _loading = false;

  bool get tickerActive => _ticker?.isActive ?? false;

  Future<void> load({bool showLoading = true}) async {
    if (_loading) return;
    _loading = true;
    final current = _now();
    final dayRange = HomeDayRange.forLocalDay(current);
    final weekRange = HomeWeekRange.forLocalWeek(current);

    if (showLoading || state.status == HomeStatus.initial) {
      emit(
        state.copyWith(
          status: HomeStatus.loading,
          now: current,
          dayStart: dayRange.start,
          weekStart: weekRange.start,
          errorMessage: null,
        ),
      );
    }

    if (_isTrainer && _bookingRequestsRepository != null) {
      emit(state.copyWith(pendingCountStatus: PendingCountStatus.loading));
    }
    if (!_isTrainer && _sessionPackagesRepository != null) {
      emit(state.copyWith(studentPackageStatus: StudentPackageStatus.loading));
    }
    final pendingCountLoad = _loadPendingCount();
    final studentPackageLoad = _loadStudentPackage();

    try {
      final sessions = await _scheduleRepository.listSessions(
        from: weekRange.start,
        to: weekRange.end,
      );
      emit(
        state.copyWith(
          status: HomeStatus.success,
          sessions: sessions,
          now: _now(),
          dayStart: dayRange.start,
          weekStart: weekRange.start,
          errorMessage: null,
          historyExpanded: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          now: _now(),
          dayStart: dayRange.start,
          weekStart: weekRange.start,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _loading = false;
    }
    await Future.wait([pendingCountLoad, studentPackageLoad]);
  }

  Future<void> refresh() => load(showLoading: false);

  Future<void> _loadPendingCount() async {
    if (!_isTrainer || _bookingRequestsRepository == null) return;
    try {
      final count = await _bookingRequestsRepository.pendingCount();
      emit(
        state.copyWith(
          pendingCountStatus: PendingCountStatus.success,
          pendingRequestCount: count,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          pendingCountStatus: PendingCountStatus.failure,
          pendingRequestCount: null,
        ),
      );
    }
  }

  Future<void> _loadStudentPackage() async {
    if (_isTrainer || _sessionPackagesRepository == null) return;
    try {
      final packages = await _sessionPackagesRepository.list();
      final active = packages.where((p) => p.isActive).toList();
      final ended = packages
          .where((p) => p.isExhausted || p.isExpired)
          .toList();
      final pkg = active.isNotEmpty
          ? active.first
          : (ended.isNotEmpty ? ended.first : null);
      if (pkg == null) {
        emit(
          state.copyWith(
            studentPackageStatus: StudentPackageStatus.success,
            studentPackageRemaining: null,
            studentPackageExhausted: false,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          studentPackageStatus: StudentPackageStatus.success,
          studentPackageRemaining: pkg.remainingSessions,
          studentPackageExhausted: pkg.isExhausted || pkg.isExpired,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          studentPackageStatus: StudentPackageStatus.failure,
          studentPackageRemaining: null,
          studentPackageExhausted: false,
        ),
      );
    }
  }

  Future<void> tick() async {
    final current = _now();
    final dayRange = HomeDayRange.forLocalDay(current);
    final weekRange = HomeWeekRange.forLocalWeek(current);
    if (state.dayStart != dayRange.start ||
        state.weekStart != weekRange.start) {
      await load(showLoading: false);
      return;
    }
    emit(state.copyWith(now: current));
  }

  void toggleHistory() {
    emit(state.copyWith(historyExpanded: !state.historyExpanded));
  }

  void toggleUpcoming() {
    emit(state.copyWith(upcomingExpanded: !state.upcomingExpanded));
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await super.close();
  }
}
