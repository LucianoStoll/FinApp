import 'package:finapp/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a tela inicial do FinApp', (tester) async {
    await tester.pumpWidget(const FinApp());
    await tester.pumpAndSettle();

    expect(find.text('Fundação do FinApp pronta'), findsOneWidget);
  });
}
