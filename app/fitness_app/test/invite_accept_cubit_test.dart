import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitness_app/core/network/api_exception.dart';
import 'package:fitness_app/features/invitations/data/invitation_models.dart';
import 'package:fitness_app/features/invitations/data/invitations_repository.dart';
import 'package:fitness_app/features/invitations/presentation/cubit/invite_accept_cubit.dart';
import 'package:fitness_app/features/invitations/presentation/cubit/invite_accept_state.dart';

class MockInvitationsRepository extends Mock implements InvitationsRepository {}

void main() {
  late MockInvitationsRepository repository;

  setUp(() {
    repository = MockInvitationsRepository();
    when(() => repository.clearPendingToken()).thenAnswer((_) async {});
  });

  group('InviteAcceptCubit', () {
    blocTest<InviteAcceptCubit, InviteAcceptState>(
      'accept success',
      build: () {
        when(() => repository.accept(any())).thenAnswer(
          (_) async => const AcceptInvitationResult(
            coachId: 'c1',
            studentId: 's1',
            coachEmail: 'coach@example.com',
          ),
        );
        return InviteAcceptCubit(
          repository: repository,
          initialToken: 'tok_abcdefghijklmnop',
        );
      },
      act: (cubit) => cubit.accept(),
      expect: () => [
        isA<InviteAcceptState>().having(
          (s) => s.isSubmitting,
          'submitting',
          true,
        ),
        isA<InviteAcceptState>()
            .having((s) => s.isSubmitting, 'submitting', false)
            .having((s) => s.result?.coachEmail, 'email', 'coach@example.com'),
      ],
    );

    test('отклонённый токен (4xx) не остаётся в ожидании', () async {
      when(
        () => repository.accept(any()),
      ).thenThrow(ApiException('Приглашение истекло', statusCode: 409));
      final cubit = InviteAcceptCubit(
        repository: repository,
        initialToken: 'tok_abcdefghijklmnop',
      );

      expect(await cubit.accept(), isFalse);
      verify(() => repository.clearPendingToken()).called(1);
      await cubit.close();
    });

    blocTest<InviteAcceptCubit, InviteAcceptState>(
      'accept failure',
      build: () {
        when(
          () => repository.accept(any()),
        ).thenThrow(ApiException('Приглашение истекло', statusCode: 409));
        return InviteAcceptCubit(
          repository: repository,
          initialToken: 'tok_abcdefghijklmnop',
        );
      },
      act: (cubit) => cubit.accept(),
      expect: () => [
        isA<InviteAcceptState>().having(
          (s) => s.isSubmitting,
          'submitting',
          true,
        ),
        isA<InviteAcceptState>()
            .having((s) => s.isSubmitting, 'submitting', false)
            .having((s) => s.errorMessage, 'error', 'Приглашение истекло'),
      ],
    );
  });
}
