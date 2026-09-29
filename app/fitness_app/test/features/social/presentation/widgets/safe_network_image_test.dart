import 'package:fitness_app/features/social/presentation/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses fallback for non-HTTPS images', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SafeNetworkImage(
          url: 'http://example.com/avatar.png',
          width: 80,
          height: 80,
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
