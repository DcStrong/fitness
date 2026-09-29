import 'package:fitness_app/features/schedule/data/schedule_models.dart';
import 'package:fitness_app/features/finance/data/finance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrainingSession session(String id, String status) {
    return TrainingSession(
      id: id,
      coachId: 'c',
      studentId: 's',
      startsAt: '2026-08-08T10:00:00.000Z',
      endsAt: '2026-08-08T11:00:00.000Z',
      status: status,
      createdBy: 'coach',
      finance: const SessionFinance(status: 'not_tracked'),
    );
  }

  test('upcoming vs archive split', () {
    final all = [
      session('1', 'booked'),
      session('2', 'cancelled'),
      session('3', 'completed'),
      session('4', 'no_show'),
    ];
    final upcoming = all.where((s) => s.status == 'booked').toList();
    final archive = all.where((s) => s.status != 'booked').toList();
    expect(upcoming.map((s) => s.id), ['1']);
    expect(archive.map((s) => s.id), ['2', '3', '4']);
  });
}
