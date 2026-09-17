import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplecalculator/main.dart';

void main() {
  testWidgets('performs arithmetic and records history', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    await tester.tap(find.text('7'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('display')), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.text('7 + 3'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
  });

  testWidgets('handles decimals and division by zero', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    await tester.tap(find.text('5'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('÷'));
    await tester.tap(find.text('0').last);
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('Error'), findsOneWidget);
  });
}
