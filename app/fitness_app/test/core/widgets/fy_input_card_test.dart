import 'package:fitness_app/app/theme/app_colors.dart';
import 'package:fitness_app/app/theme/app_theme.dart';
import 'package:fitness_app/core/widgets/fy_input_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders card styling and preserves field behavior', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    var submittedValue = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: FyInputCard(
              label: 'Email',
              icon: Icons.email_outlined,
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (value) => submittedValue = value,
              validator: (value) =>
                  value == null || !value.contains('@') ? 'Некорректно' : null,
            ),
          ),
        ),
      ),
    );

    final fieldBox = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FyInputCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .firstWhere((box) => box.decoration is BoxDecoration);
    final decoration = fieldBox.decoration as BoxDecoration;
    final editableText = tester.widget<EditableText>(find.byType(EditableText));

    expect(decoration.color, AppColors.surface);
    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(decoration.boxShadow, isNotEmpty);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(editableText.controller, same(controller));
    expect(editableText.keyboardType, TextInputType.emailAddress);
    expect(editableText.textInputAction, TextInputAction.done);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Некорректно'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Некорректно'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submittedValue, 'user@example.com');
  });

  testWidgets('keeps input height fixed when error appears', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: FyInputCard(
              label: 'Email',
              icon: Icons.email_outlined,
              variant: FyInputCardVariant.outlined,
              validator: (value) => 'Некорректный email',
            ),
          ),
        ),
      ),
    );

    final inputChrome = find.descendant(
      of: find.byType(FyInputCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 48,
      ),
    );
    final heightBefore = tester.getSize(inputChrome).height;
    expect(heightBefore, 48);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(tester.getSize(inputChrome).height, 48);
    expect(find.text('Некорректный email'), findsOneWidget);
  });

  testWidgets('supports obscure text and a unit chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: FyInputCard(
            label: 'Пароль',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            unit: 'Kg',
          ),
        ),
      ),
    );

    final editableText = tester.widget<EditableText>(find.byType(EditableText));

    expect(editableText.obscureText, isTrue);
    expect(find.text('Kg'), findsOneWidget);
  });
}
