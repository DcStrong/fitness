import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../booking_requests/data/booking_request_models.dart';
import '../../../booking_requests/data/booking_requests_repository.dart';
import '../../../invitations/data/invitation_models.dart';
import '../../../invitations/data/invitations_repository.dart';
import '../../data/session_package_models.dart';
import '../../data/session_packages_repository.dart';
import 'session_packages_state.dart';

class SessionPackagesCubit extends Cubit<SessionPackagesState> {
  SessionPackagesCubit({
    required SessionPackagesRepository packagesRepository,
    required InvitationsRepository invitationsRepository,
    required BookingRequestsRepository bookingRequestsRepository,
  }) : _packages = packagesRepository,
       _invitations = invitationsRepository,
       _bookingRequests = bookingRequestsRepository,
       super(const SessionPackagesState());

  final SessionPackagesRepository _packages;
  final InvitationsRepository _invitations;
  final BookingRequestsRepository _bookingRequests;

  Future<void> load() async {
    emit(
      state.copyWith(status: SessionPackagesStatus.loading, errorMessage: null),
    );
    try {
      final relationships = await _invitations.listRelationships();
      final packages = await _packages.list();
      final pendingIds = await _loadPendingStudentIds();

      final students = relationships
          .where((r) => r.roleForViewer == 'coach')
          .toList();

      final byStudent = <String, SessionPackage>{};
      for (final pkg in packages) {
        final existing = byStudent[pkg.studentId];
        if (existing == null) {
          byStudent[pkg.studentId] = pkg;
          continue;
        }
        if (pkg.isActive) {
          byStudent[pkg.studentId] = pkg;
        } else if (!existing.isActive &&
            !pkg.isArchived &&
            (existing.isArchived ||
                pkg.createdAt.compareTo(existing.createdAt) > 0)) {
          byStudent[pkg.studentId] = pkg;
        }
      }

      final knownIds = {for (final s in students) s.studentId};
      final rows = <StudentPackageRow>[
        for (final s in students)
          StudentPackageRow(
            student: s,
            package: byStudent[s.studentId],
            category: categorizeStudentRow(
              package: byStudent[s.studentId],
              hasPendingRequest: pendingIds.contains(s.studentId),
            ),
          ),
      ];

      for (final studentId in pendingIds) {
        if (knownIds.contains(studentId)) continue;
        rows.add(
          StudentPackageRow(
            student: RelationshipItem(
              id: 'pending-$studentId',
              coachId: '',
              studentId: studentId,
              roleForViewer: 'coach',
              studentDisplayName: 'Ожидает решения',
            ),
            package: byStudent[studentId],
            category: StudentPaymentCategory.waiting,
          ),
        );
      }

      emit(
        state.copyWith(
          status: SessionPackagesStatus.ready,
          rows: rows,
          errorMessage: null,
          busy: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SessionPackagesStatus.failure,
          errorMessage: error.toString(),
          busy: false,
        ),
      );
    }
  }

  void setFilter(StudentListFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<Set<String>> _loadPendingStudentIds() async {
    try {
      final page = await _bookingRequests.inbox(
        page: 1,
        limit: 100,
        status: BookingRequestStatus.pending,
      );
      return {for (final item in page.items) item.counterpart.id};
    } catch (_) {
      return {};
    }
  }

  Future<bool> createPackage({
    required String studentId,
    required int totalSessions,
    DateTime? expiresAt,
  }) async {
    emit(state.copyWith(busy: true, errorMessage: null));
    try {
      await _packages.create(
        studentId: studentId,
        totalSessions: totalSessions,
        expiresAt: expiresAt,
      );
      await load();
      return true;
    } catch (error) {
      emit(state.copyWith(busy: false, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> extendPackage({
    required String packageId,
    required int addSessions,
    DateTime? expiresAt,
  }) async {
    emit(state.copyWith(busy: true, errorMessage: null));
    try {
      await _packages.extend(
        packageId: packageId,
        addSessions: addSessions,
        expiresAt: expiresAt,
      );
      await load();
      return true;
    } catch (error) {
      emit(state.copyWith(busy: false, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> archivePackage(String packageId) async {
    emit(state.copyWith(busy: true, errorMessage: null));
    try {
      await _packages.archive(packageId);
      await load();
      return true;
    } catch (error) {
      emit(state.copyWith(busy: false, errorMessage: error.toString()));
      return false;
    }
  }
}
