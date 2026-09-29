import 'package:finapp/app/app.dart';
import 'package:finapp/core/di/injection.dart';
import 'package:finapp/features/dashboard/domain/dashboard_repository.dart';
import 'package:finapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

class _DashboardStub implements DashboardRepository {
  @override
  Future<DashboardSummary> load(DateTime month) async => DashboardSummary(
    month: month,
    currencies: const [DashboardCurrencySummary(currencyCode: 'BRL',
      currentBalanceMinor: 12000, projectedBalanceMinor: 13000,
      incomeMinor: 4000, expenseMinor: 2000)],
    recent: const [],
  );
}

void main() {
  testWidgets('exibe o resumo financeiro na tela inicial', (tester) async {
    getIt.registerSingleton<DashboardRepository>(_DashboardStub());
    addTearDown(getIt.reset);
    await tester.pumpWidget(const FinApp());
    await tester.pumpAndSettle();

    expect(find.text('Somia'), findsOneWidget);
    expect(find.text('Resultado do mês'), findsOneWidget);
    expect(find.text('R\$ 20,00'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
  });
}
