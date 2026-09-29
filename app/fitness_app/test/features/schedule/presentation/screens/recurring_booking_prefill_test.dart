import 'package:fitness_app/features/schedule/presentation/screens/recurring_booking_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromLocalDateTime maps weekday and start minute', () {
    final local = DateTime(2026, 8, 4, 13, 0); // Tuesday
    final prefill = RecurringBookingPrefill.fromLocalDateTime(
      local,
      mode: 'online',
    );

    expect(local.weekday, DateTime.tuesday);
    expect(prefill.weekdays, {DateTime.tuesday});
    expect(prefill.startMinute, 13 * 60);
    expect(prefill.mode, 'online');
    expect(prefill.timeOfDay, const TimeOfDay(hour: 13, minute: 0));
  });
}
