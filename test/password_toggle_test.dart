import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landowner/shared/forms/fields/text_fields.dart';

void main() {
  testWidgets('password field hides by default and the eye toggles it', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Material(child: HomelyTextField(value: '', onChanged: (_) {}, obscure: true)),
    ));
    bool obscured() => t.widget<TextField>(find.byType(TextField)).obscureText;

    await t.enterText(find.byType(TextField), 'secret1');
    expect(obscured(), isTrue);

    await t.tap(find.bySemanticsLabel('Show password'));
    await t.pump();
    expect(obscured(), isFalse);

    await t.tap(find.bySemanticsLabel('Hide password'));
    await t.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('normal text fields have no eye button', (t) async {
    await t.pumpWidget(MaterialApp(home: Material(child: HomelyTextField(value: '', onChanged: (_) {}))));
    expect(find.bySemanticsLabel('Show password'), findsNothing);
  });
}
