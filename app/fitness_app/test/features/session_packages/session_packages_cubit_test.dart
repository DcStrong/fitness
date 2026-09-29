import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/features/booking_requests/data/booking_request_models.dart';
import 'package:fitness_app/features/booking_requests/data/booking_requests_repository.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/session_packages/data/session_package_models.dart';
import 'package:fitness_app/features/session_packages/data/session_packages_repository.dart';
import 'package:fitness_app/features/session_packages/presentation/cubit/session_packages_cubit.dart';
import 'package:fitness_app/features/session_packages/presentation/cubit/session_packages_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackages extends Mock implements SessionPackagesRepository {}

class _MockInvitations extends Mock implements InvitationsRepository {}

class _MockBooking extends Mock implements BookingRequestsRepository {}

void main() {
  late _MockPackages packages;
  late _MockInvitations invitations;
  late _MockBooking booking;

  setUp(() {
    packages = _MockPackages();
    invitations = _MockInvitations();
    booking = _MockBooking();
    when(
      () => booking.inbox(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => const BookingRequestPage(
        items: [],
        page: 1,
        limit: 100,
        total: 0,
        totalPages: 0,
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(BookingRequestStatus.pending);
  });

  SessionPackage pkg({
    String id = 'p1',
    String studentId = 's1',
    int remaining = 3,
    String status = 'active',
  }) {
    return SessionPackage(
      id: id,
      coachId: 'c1',
      studentId: studentId,
      totalSessions: 8,
      remainingSessions: remaining,
      status: status,
      createdAt: '2026-08-01T00:00:00.000Z',
      updatedAt: '2026-08-01T00:00:00.000Z',
    );
  }

  RelationshipItem student({String id = 's1'}) {
    return RelationshipItem(
      id: 'rel-$id',
      coachId: 'c1',
      studentId: id,
      roleForViewer: 'coach',
      studentEmail: '$id@test.com',
    );
  }

  SessionPackagesCubit buildCubit() => SessionPackagesCubit(
    packagesRepository: packages,
    invitationsRepository: invitations,
    bookingRequestsRepository: booking,
  );

  blocTest<SessionPackagesCubit, SessionPackagesState>(
    'load показывает остаток для ученика',
    build: () {
      when(
        () => invitations.listRelationships(),
      ).thenAnswer((_) async => [student()]);
      when(() => packages.list()).thenAnswer((_) async => [pkg()]);
      return buildCubit();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<SessionPackagesState>().having(
        (s) => s.status,
        'status',
        SessionPackagesStatus.loading,
      ),
      isA<SessionPackagesState>()
          .having((s) => s.status, 'status', SessionPackagesStatus.ready)
          .having((s) => s.rows.length, 'rows', 1)
          .having(
            (s) => s.rows.first.package?.remainingSessions,
            'remaining',
            3,
          )
          .having(
            (s) => s.rows.first.category,
            'category',
            StudentPaymentCategory.paid,
          ),
    ],
  );

  blocTest<SessionPackagesCubit, SessionPackagesState>(
    'pending request marks student as waiting over paid package',
    build: () {
      when(
        () => invitations.listRelationships(),
      ).thenAnswer((_) async => [student(), student(id: 's2')]);
      when(
        () => packages.list(),
      ).thenAnswer((_) async => [pkg(), pkg(id: 'p2', studentId: 's2')]);
      when(
        () => booking.inbox(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => BookingRequestPage(
          items: [
            BookingRequest(
              id: 'br1',
              coachId: 'c1',
              studentId: 's1',
              scheduleSlotId: 'slot1',
              status: BookingRequestStatus.pending,
              quotedPriceMinor: '1000',
              quotedCurrency: 'RUB',
              expiresAt: DateTime.utc(2026, 8, 2),
              requestedSlot: BookingRequestSlotSummary(
                id: 'slot1',
                startsAt: DateTime.utc(2026, 8, 10, 10),
                endsAt: DateTime.utc(2026, 8, 10, 11),
                mode: 'offline',
              ),
              counterpart: const BookingRequestCounterpart(
                id: 's1',
                label: 's1@test.com',
              ),
              createdAt: DateTime.utc(2026, 8, 1),
              updatedAt: DateTime.utc(2026, 8, 1),
            ),
          ],
          page: 1,
          limit: 100,
          total: 1,
          totalPages: 1,
        ),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load();
      cubit.setFilter(StudentListFilter.waiting);
    },
    verify: (cubit) {
      expect(
        cubit.state.rows
            .firstWhere((r) => r.student.studentId == 's1')
            .category,
        StudentPaymentCategory.waiting,
      );
      expect(
        cubit.state.rows
            .firstWhere((r) => r.student.studentId == 's2')
            .category,
        StudentPaymentCategory.paid,
      );
      expect(cubit.state.visibleRows.map((r) => r.student.studentId), ['s1']);
    },
  );

  test('categorizeStudentRow priority', () {
    expect(
      categorizeStudentRow(package: pkg(), hasPendingRequest: true),
      StudentPaymentCategory.waiting,
    );
    expect(
      categorizeStudentRow(package: pkg(), hasPendingRequest: false),
      StudentPaymentCategory.paid,
    );
    expect(
      categorizeStudentRow(package: null, hasPendingRequest: false),
      StudentPaymentCategory.unpaid,
    );
  });

  blocTest<SessionPackagesCubit, SessionPackagesState>(
    'createPackage вызывает API и перезагружает',
    build: () {
      when(
        () => invitations.listRelationships(),
      ).thenAnswer((_) async => [student()]);
      when(() => packages.list()).thenAnswer((_) async => [pkg(remaining: 8)]);
      when(
        () => packages.create(
          studentId: any(named: 'studentId'),
          totalSessions: any(named: 'totalSessions'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => pkg(remaining: 8));
      return buildCubit();
    },
    act: (cubit) => cubit.createPackage(studentId: 's1', totalSessions: 8),
    verify: (_) {
      verify(
        () =>
            packages.create(studentId: 's1', totalSessions: 8, expiresAt: null),
      ).called(1);
    },
  );

  blocTest<SessionPackagesCubit, SessionPackagesState>(
    'extendPackage продлевает exhausted',
    build: () {
      when(
        () => invitations.listRelationships(),
      ).thenAnswer((_) async => [student()]);
      when(
        () => packages.list(),
      ).thenAnswer((_) async => [pkg(remaining: 4, status: 'active')]);
      when(
        () => packages.extend(
          packageId: any(named: 'packageId'),
          addSessions: any(named: 'addSessions'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => pkg(remaining: 4));
      return buildCubit();
    },
    act: (cubit) => cubit.extendPackage(packageId: 'p1', addSessions: 4),
    verify: (_) {
      verify(
        () => packages.extend(packageId: 'p1', addSessions: 4, expiresAt: null),
      ).called(1);
    },
  );
}
