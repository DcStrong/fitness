import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/session_packages/data/session_package_models.dart';
import 'package:fitness_app/features/session_packages/presentation/cubit/session_packages_cubit.dart';
import 'package:fitness_app/features/session_packages/presentation/cubit/session_packages_state.dart';
import 'package:fitness_app/features/session_packages/presentation/session_packages_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCubit extends MockCubit<SessionPackagesState>
    implements SessionPackagesCubit {}

RelationshipItem _student(String id, {String? name, String? email}) =>
    RelationshipItem(
      id: 'r-$id',
      coachId: 'c1',
      studentId: id,
      roleForViewer: 'trainer',
      studentDisplayName: name,
      studentEmail: email,
    );

void main() {
  late _MockCubit cubit;

  Future<void> pump(WidgetTester tester, SessionPackagesState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<SessionPackagesState>.empty(),
      initialState: state,
    );
    when(() => cubit.load()).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<SessionPackagesCubit>.value(
          value: cubit,
          child: const SessionPackagesView(),
        ),
      ),
    );
  }

  setUpAll(() => registerFallbackValue(StudentListFilter.all));

  setUp(() => cubit = _MockCubit());

  final state = SessionPackagesState(
    status: SessionPackagesStatus.ready,
    rows: [
      StudentPackageRow(
        student: _student('s1', name: 'Ольга Смирнова', email: 'olga@mail.ru'),
        package: const SessionPackage(
          id: 'p1',
          coachId: 'c1',
          studentId: 's1',
          totalSessions: 8,
          remainingSessions: 6,
          status: 'active',
          createdAt: '2026-08-01T00:00:00.000Z',
          updatedAt: '2026-08-01T00:00:00.000Z',
        ),
        category: StudentPaymentCategory.paid,
      ),
      StudentPackageRow(student: _student('s2', email: 'pavel@mail.ru')),
      StudentPackageRow(
        student: _student('s3', name: 'Кирилл Орлов', email: 'kirill@mail.ru'),
        category: StudentPaymentCategory.waiting,
      ),
    ],
  );

  testWidgets('строки: имя, почта под именем, статус словом', (tester) async {
    await pump(tester, state);

    expect(find.text('Ученики'), findsOneWidget);
    expect(find.byKey(const Key('students-invite')), findsOneWidget);
    expect(find.text('Ольга Смирнова'), findsOneWidget);
    expect(find.text('olga@mail.ru'), findsOneWidget);
    expect(find.text('Осталось 6'), findsOneWidget);
    // Without a name the e-mail is the only line.
    expect(find.text('pavel@mail.ru'), findsOneWidget);
    expect(find.text('Нет пакета'), findsOneWidget);
    expect(find.text('Ожидает'), findsWidgets);
    expect(find.byKey(const Key('package-manage-s1')), findsOneWidget);
  });

  testWidgets('поиск по имени и почте сужает список', (tester) async {
    await pump(tester, state);

    await tester.enterText(find.byKey(const Key('students-search')), 'орлов');
    await tester.pump();
    expect(find.byKey(const Key('package-row-s3')), findsOneWidget);
    expect(find.byKey(const Key('package-row-s1')), findsNothing);

    await tester.enterText(find.byKey(const Key('students-search')), 'pavel');
    await tester.pump();
    expect(find.byKey(const Key('package-row-s2')), findsOneWidget);
    expect(find.byKey(const Key('package-row-s3')), findsNothing);

    await tester.enterText(find.byKey(const Key('students-search')), 'zzz');
    await tester.pump();
    expect(find.text('Нет учеников по этому запросу.'), findsOneWidget);
  });

  testWidgets('фильтр вызывает кубит', (tester) async {
    when(() => cubit.setFilter(any())).thenAnswer((_) {});
    await pump(tester, state);

    await tester.tap(find.byKey(const Key('students-filter-waiting')));
    verify(() => cubit.setFilter(StudentListFilter.waiting)).called(1);
  });
}
