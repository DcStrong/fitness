import 'package:fitness_app/features/social/presentation/helper/phone_mask.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatRuPhone builds the mask progressively', () {
    expect(formatRuPhone(''), '');
    expect(formatRuPhone('9'), '+7 (9');
    expect(formatRuPhone('999123'), '+7 (999) 123');
    expect(formatRuPhone('+79991234567'), '+7 (999) 123-45-67');
    expect(formatRuPhone('89991234567'), '+7 (999) 123-45-67');
    expect(formatRuPhone('99912345678999'), '+7 (999) 123-45-67');
  });

  test('normalizeRuPhone returns E.164 only for complete numbers', () {
    expect(normalizeRuPhone('+7 (999) 123-45-67'), '+79991234567');
    expect(normalizeRuPhone('8 999 123 45 67'), '+79991234567');
    expect(normalizeRuPhone('+7 (999) 123'), isNull);
    expect(normalizeRuPhone(''), isNull);
  });

  testWidgets('field applies mask and limits length', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: const [RuPhoneInputFormatter()],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '89991234567000');
    expect(controller.text, '+7 (999) 123-45-67');
    await tester.enterText(find.byType(TextField), '9991');
    expect(controller.text, '+7 (999) 1');
  });
}
