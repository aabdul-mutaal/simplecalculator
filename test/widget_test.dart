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

  testWidgets('checks for 2+2=4', (tester) async { //Test 1
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    //Clicks the buttons
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.tap(find.text('+').last);
    await tester.pump();
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.tap(find.text('=').last);
    await tester.pump();
    //Check
    expect(find.text('4'), findsNWidgets(2));
  });

  testWidgets('checks for 99÷3=33', (tester) async { //Test 2
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    //Clicks the buttons
    await tester.tap(find.text('9').last);
    await tester.tap(find.text('9').last);
    await tester.pump();
    await tester.tap(find.text('÷').last);
    await tester.pump();
    await tester.tap(find.text('3').last);
    await tester.pump();
    await tester.tap(find.text('=').last);
    await tester.pump();
    //Check
    expect(find.text('33'), findsNWidgets(1));
  });

  testWidgets('checks for 5+5=10', (tester) async { //Test 3
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    //Clicks the buttons
    await tester.tap(find.text('5').last);
    await tester.pump();
    await tester.tap(find.text('+').last);
    await tester.pump();
    await tester.tap(find.text('5').last);
    await tester.pump();
    await tester.tap(find.text('=').last);
    await tester.pump();
    //Check
    expect(find.text('10'), findsNWidgets(1));
  });

  testWidgets('checks for 25+25=50', (tester) async { //Test 4
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    //Clicks the buttons
    await tester.tap(find.text('2').last);
    await tester.tap(find.text('5').last);
    await tester.pump();
    await tester.tap(find.text('+').last);
    await tester.pump();
    await tester.tap(find.text('2').last);
    await tester.tap(find.text('5').last);
    await tester.pump();
    await tester.tap(find.text('=').last);
    await tester.pump();
    //Check
    expect(find.text('50'), findsNWidgets(1));
  });

  testWidgets('checks for 9÷9=1', (tester) async { //Test 5
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    //Clicks the buttons
    await tester.tap(find.text('9').last);
    await tester.pump();
    await tester.tap(find.text('÷').last);
    await tester.pump();
    await tester.tap(find.text('9').last);
    await tester.pump();
    await tester.tap(find.text('=').last);
    await tester.pump();
    //Check
    expect(find.text('1'), findsNWidgets(2));
  });
}
