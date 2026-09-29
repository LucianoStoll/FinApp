import 'package:finapp/app/app.dart';
import 'package:finapp/core/di/injection.dart';
import 'package:finapp/core/routing/app_router.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/accounts/domain/accounts_repository.dart';
import 'package:finapp/features/categories/domain/category.dart';
import 'package:finapp/features/categories/domain/categories_repository.dart';
import 'package:finapp/features/dashboard/domain/dashboard_repository.dart';
import 'package:finapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:finapp/features/transactions/domain/transactions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DashboardStub implements DashboardRepository {
  @override
  Future<DashboardSummary> load(DateTime month) async =>
    DashboardSummary(month: month, currencies: const [], recent: const []);
}

class _AccountsStub implements AccountsRepository {
  @override
  Future<List<Account>> list() async => [];
  @override
  Future<Account> create(AccountDraft draft) => throw UnimplementedError();
  @override
  Future<Account> update(String id, AccountDraft draft) => throw UnimplementedError();
  @override
  Future<Account> setArchived(String id, {required bool archived}) =>
    throw UnimplementedError();
}

class _CategoriesStub implements CategoriesRepository {
  @override
  Future<List<FinanceCategory>> list() async => [];
  @override
  Future<FinanceCategory> create(CategoryDraft draft) => throw UnimplementedError();
  @override
  Future<FinanceCategory> update(String id, CategoryDraft draft) =>
    throw UnimplementedError();
  @override
  Future<FinanceCategory> setArchived(String id, {required bool archived}) =>
    throw UnimplementedError();
}

class _TransactionsStub implements TransactionsRepository {
  final requestedTypes = <TransactionType?>[];
  final items = [
    FinancialTransaction(id: 'income', description: 'Salário',
      type: TransactionType.income, amountMinor: 500000,
      date: DateTime(2026, 9, 29), isEffective: true,
      accountId: 'a', accountName: 'Conta', categoryId: null,
      categoryName: null, currencyCode: 'BRL'),
    FinancialTransaction(id: 'expense', description: 'Mercado',
      type: TransactionType.expense, amountMinor: 18000,
      date: DateTime(2026, 9, 29), isEffective: false,
      accountId: 'a', accountName: 'Conta', categoryId: null,
      categoryName: null, currencyCode: 'BRL'),
  ];
  @override
  Future<List<FinancialTransaction>> list([TransactionFilter filter =
    const TransactionFilter()]) async {
    requestedTypes.add(filter.type);
    return items.where((item) => filter.type == null || item.type == filter.type)
      .toList();
  }
  @override
  Future<FinancialTransaction> create(TransactionDraft draft) =>
    throw UnimplementedError();
  @override
  Future<FinancialTransaction> update(String id, TransactionDraft draft) =>
    throw UnimplementedError();
  @override
  Future<void> setEffective(String id, {required bool effective}) =>
    throw UnimplementedError();
  @override
  Future<void> delete(String id) => throw UnimplementedError();
}

void main() {
  testWidgets('drawer mobile separa receitas e despesas sem barra inferior',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final transactions = _TransactionsStub();
    getIt.registerSingleton<DashboardRepository>(_DashboardStub());
    getIt.registerSingleton<TransactionsRepository>(transactions);
    getIt.registerSingleton<AccountsRepository>(_AccountsStub());
    getIt.registerSingleton<CategoriesRepository>(_CategoriesStub());
    addTearDown(() async {
      appRouter.go('/');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    });
    appRouter.go('/');
    await tester.pumpWidget(const FinApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    for (final label in ['Resumo', 'Receitas', 'Despesas', 'Transferências',
      'Contas', 'Categorias', 'Configurações']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.byKey(const ValueKey('menu-/income')));
    await tester.pumpAndSettle();
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Mercado'), findsNothing);
    expect(transactions.requestedTypes.last, TransactionType.income);

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(find.byKey(const ValueKey('menu-/income')))
      .selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('menu-/expenses')));
    await tester.pumpAndSettle();
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Salário'), findsNothing);
    expect(transactions.requestedTypes.last, TransactionType.expense);
    expect(find.text('Efetivar'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar lançamento ou transferência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receita').last);
    await tester.pumpAndSettle();
    expect(find.text('Novo lançamento'), findsOneWidget);
    expect(find.text('Receita'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Receitas'), findsOneWidget);
  });

  testWidgets('sidebar larga mantém as mesmas seções', (tester) async {
    tester.view.physicalSize = const Size(1100, 850);
    tester.view.devicePixelRatio = 1;
    getIt.registerSingleton<DashboardRepository>(_DashboardStub());
    getIt.registerSingleton<TransactionsRepository>(_TransactionsStub());
    getIt.registerSingleton<AccountsRepository>(_AccountsStub());
    getIt.registerSingleton<CategoriesRepository>(_CategoriesStub());
    addTearDown(() async {
      appRouter.go('/');
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await getIt.reset();
    });
    appRouter.go('/');
    await tester.pumpWidget(const FinApp());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Abrir menu'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu-/income')));
    await tester.pumpAndSettle();
    expect(find.text('Salário'), findsOneWidget);
  });
}
