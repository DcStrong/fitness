import 'package:fitness_app/features/schedule/data/recurring_booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson читает studentDisplayName и studentEmail', () {
    final booking = RecurringBooking.fromJson(const {
      'id': 'rb1',
      'coachId': 'c1',
      'studentId': 's1-long-id-value',
      'studentDisplayName': 'Иван',
      'studentEmail': 'ivan@example.com',
      'weekdays': [6],
      'startMinute': 600,
      'mode': 'offline',
      'timezone': 'Europe/Moscow',
      'status': 'active',
      'horizonWeeksOverride': null,
      'createdAt': '2026-08-04T00:00:00.000Z',
      'updatedAt': '2026-08-04T00:00:00.000Z',
      'cancelledAt': null,
    });

    expect(booking.studentDisplayName, 'Иван');
    expect(booking.studentEmail, 'ivan@example.com');
    expect(booking.studentTitle, 'Иван');
  });

  test('studentTitle падает на email и id', () {
    final byEmail = RecurringBooking.fromJson(const {
      'id': 'rb1',
      'coachId': 'c1',
      'studentId': 's1-long-id-value',
      'studentDisplayName': null,
      'studentEmail': 'ivan@example.com',
      'weekdays': [6],
      'startMinute': 600,
      'mode': 'offline',
      'timezone': 'Europe/Moscow',
      'status': 'active',
      'horizonWeeksOverride': null,
      'createdAt': '2026-08-04T00:00:00.000Z',
      'updatedAt': '2026-08-04T00:00:00.000Z',
      'cancelledAt': null,
    });
    expect(byEmail.studentTitle, 'ivan@example.com');

    final byId = RecurringBooking.fromJson(const {
      'id': 'rb1',
      'coachId': 'c1',
      'studentId': 'abcdefghij',
      'weekdays': [6],
      'startMinute': 600,
      'mode': 'offline',
      'timezone': 'Europe/Moscow',
      'status': 'active',
      'horizonWeeksOverride': null,
      'createdAt': '2026-08-04T00:00:00.000Z',
      'updatedAt': '2026-08-04T00:00:00.000Z',
      'cancelledAt': null,
    });
    expect(byId.studentTitle, 'abcdefgh');
  });
}
