import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canon_web_nav_example/main.dart';

void main() {
  testWidgets('boots to the catalog; a tap lands on the typed product screen',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp.router(routerDelegate: Screen.manager));
    Screen.goCatalog();
    await tester.pumpAndSettle();
    expect(find.text('catalog'), findsOneWidget);

    await tester.tap(find.text('product 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('product 0'), findsOneWidget);
  });
}
