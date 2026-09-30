import 'dart:io';
import 'dart:typed_data';

import 'package:finapp/core/di/injection.dart';
import 'package:finapp/core/routing/somia_shell.dart';
import 'package:finapp/core/theme/app_theme.dart';
import 'package:finapp/features/dashboard/domain/dashboard_repository.dart';
import 'package:finapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:finapp/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _DashboardStub implements DashboardRepository {
  final requestedMonths = <DateTime>[];

  @override
  Future<DashboardSummary> load(DateTime month) async {
    requestedMonths.add(month);
    return DashboardSummary(month: month, currencies: [
      DashboardCurrencySummary(
        currencyCode: 'BRL',
        currentBalanceMinor: 235000,
        projectedBalanceMinor: 290000,
        incomeMinor: 620000,
        expenseMinor: 385000,
        expensesByCategory: const [DashboardCategoryExpense('Moradia', 200000)],
        accounts: const [
          DashboardAccountBalance(
              'Conta principal', 'Conta corrente', 'BRL', 235000)
        ],
        history: [
          for (var i = 0; i < 6; i++)
            DashboardMonthTotal(
                DateTime(month.year, month.month - 5 + i),
                [400000, 520000, 440000, 560000, 530000, 620000][i],
                [300000, 340000, 350000, 420000, 440000, 385000][i])
        ],
      ),
    ], recent: [
      DashboardActivity(
          id: 'income',
          type: DashboardActivityType.income,
          description: 'Salário',
          accountLabel: 'Conta principal',
          currencyCode: 'BRL',
          amountMinor: 420000,
          date: month,
          isEffective: true),
      DashboardActivity(
          id: 'expense',
          type: DashboardActivityType.expense,
          description: 'Supermercado',
          accountLabel: 'Alimentação',
          currencyCode: 'BRL',
          amountMinor: 32050,
          date: month,
          isEffective: true),
      DashboardActivity(
          id: 'transfer',
          type: DashboardActivityType.transfer,
          description: 'Transferência',
          accountLabel: 'Conta → Carteira',
          currencyCode: 'BRL',
          amountMinor: 20000,
          date: month,
          isEffective: true),
    ]);
  }
}

Future<_DashboardStub> _mount(WidgetTester tester, Size size,
    {double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final repository = _DashboardStub();
  getIt.registerSingleton<DashboardRepository>(repository);
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await getIt.reset();
  });
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const RepaintBoundary(
      key: ValueKey('dashboard-preview'),
      child: SomiaShell(location: '/', child: DashboardPage()),
    ),
  ));
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  for (final width in [360.0, 390.0, 520.0]) {
    testWidgets('mobile $width mantém a ordem e receitas/despesas lado a lado',
        (tester) async {
      await _mount(tester, Size(width, 900));
      final balance =
          tester.getRect(find.byKey(const ValueKey('mobile-balance-BRL')));
      final income =
          tester.getRect(find.byKey(const ValueKey('mobile-income-BRL')));
      final expense =
          tester.getRect(find.byKey(const ValueKey('mobile-expense-BRL')));
      final history =
          tester.getRect(find.byKey(const ValueKey('mobile-history-BRL')));
      final recent =
          tester.getRect(find.byKey(const ValueKey('mobile-recent')));
      expect(balance.width, closeTo(width - 32, 0.1));
      expect(income.top, expense.top);
      expect(income.right, lessThan(expense.left));
      expect(balance.bottom, lessThan(income.top));
      expect(history.top, greaterThan(income.bottom));
      expect(recent.top, greaterThan(history.bottom));
      expect(find.text('Gastos por categoria'), findsNothing);
      expect(find.text('Saldo por conta'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile estreito suporta texto ampliado sem overflow',
      (tester) async {
    await _mount(tester, const Size(320, 900), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('mobile-recent')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey('dashboard-month-selector')), findsOneWidget);
  });

  testWidgets('seletor de mês permanece no cabeçalho e atualiza o resumo',
      (tester) async {
    final repository = await _mount(tester, const Size(390, 900));
    final initial = repository.requestedMonths.last;
    await tester.tap(find.byKey(const ValueKey('dashboard-month-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mês anterior'));
    await tester.pumpAndSettle();
    expect(repository.requestedMonths.last,
        DateTime(initial.year, initial.month - 1));
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop mantém métricas, categorias e saldo por conta',
      (tester) async {
    await _mount(tester, const Size(1440, 1000));
    expect(find.byKey(const ValueKey('mobile-balance-BRL')), findsNothing);
    expect(find.text('Saldo total'), findsOneWidget);
    expect(find.text('Saldo projetado'), findsOneWidget);
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('Saldo por conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('SOMIA_RENDER_PREVIEW')) {
    testWidgets('renderiza referência mobile para inspeção visual',
        (tester) async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final directory = Directory('$root/bin/cache/artifacts/material_fonts');
      final loader = FontLoader('Roboto');
      for (final file in directory.listSync().whereType<File>()) {
        if (file.path.endsWith('Roboto-Regular.ttf') ||
            file.path.endsWith('Roboto-Bold.ttf')) {
          loader.addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())));
        }
      }
      await loader.load();
      await _mount(tester, const Size(390, 844));
      await expectLater(find.byKey(const ValueKey('dashboard-preview')),
          matchesGoldenFile('dashboard-mobile-preview.png'));
    });
  }
}
