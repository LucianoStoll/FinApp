import 'package:finapp/core/widgets/effectuation_date_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openDialog(WidgetTester tester, DateTime due,
    void Function(DateTime?) onResult) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  onPressed: () async {
                    onResult(await chooseEffectuationDate(context, due));
                  },
                  child: const Text('Efetivar'))))));
  await tester.tap(find.text('Efetivar'));
  await tester.pumpAndSettle();
}

void main() {
  for (final offset in [-20, 20]) {
    final period = offset < 0 ? 'passado' : 'futuro';
    for (final useDue in [false, true]) {
      final action =
          useDue ? 'Contabilizar no vencimento' : 'Contabilizar hoje';
      testWidgets('vencimento $period permite $action', (tester) async {
        final today = DateUtils.dateOnly(DateTime.now());
        final due = DateTime(today.year, today.month, today.day + offset);
        DateTime? result;
        await openDialog(tester, due, (value) => result = value);
        expect(find.text('Contabilizar hoje'), findsOneWidget);
        expect(find.text('Contabilizar no vencimento'), findsOneWidget);
        expect(result, isNull);
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(result, useDue ? due : today);
      });
    }
    testWidgets('cancelar vencimento $period não efetiva', (tester) async {
      final today = DateUtils.dateOnly(DateTime.now());
      final due = DateTime(today.year, today.month, today.day + offset);
      DateTime? result = due;
      await openDialog(tester, due, (value) => result = value);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
  testWidgets('vencimento hoje contabiliza hoje sem confirmação',
      (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateTime(today.year, today.month, today.day, 12);
    DateTime? result;
    await openDialog(tester, due, (value) => result = value);
    expect(result, today);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
