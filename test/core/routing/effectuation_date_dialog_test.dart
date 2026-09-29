import 'package:finapp/core/widgets/effectuation_date_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vencimento futuro exige escolher hoje ou vencimento', (tester) async {
    final due = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 20));
    DateTime? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () async {
        result = await chooseEffectuationDate(context, due);
      }, child: const Text('Efetivar'))))));
    await tester.tap(find.text('Efetivar'));
    await tester.pumpAndSettle();
    expect(find.text('Contabilizar hoje'), findsOneWidget);
    expect(find.text('Contabilizar no vencimento'), findsOneWidget);
    await tester.tap(find.text('Contabilizar no vencimento'));
    await tester.pumpAndSettle();
    expect(result, due);
  });
}
