import 'package:fitness_app/features/booking_requests/presentation/widgets/fy_booking_request_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('time left reads as days, hours or minutes', () {
    expect(formatTimeLeft(const Duration(hours: 30)), '1 д');
    expect(formatTimeLeft(const Duration(hours: 5, minutes: 40)), '5 ч');
    expect(formatTimeLeft(const Duration(minutes: 40)), '40 мин');
    expect(formatTimeLeft(Duration.zero), 'Срок вышел');
  });
}
