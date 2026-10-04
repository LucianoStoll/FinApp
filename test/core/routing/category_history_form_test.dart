import 'dart:async';
import 'package:finapp/core/di/injection.dart';
import 'package:finapp/features/categories/domain/category.dart';
import 'package:finapp/features/transactions/data/category_history_repository.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:finapp/features/transactions/presentation/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'reference_form_test.dart' as forms;
import 'series_form_test.dart' as series;

const categories = [
  FinanceCategory(
      id: 'food',
      name: 'Alimentação',
      type: CategoryType.expense,
      parentId: null,
      isArchived: false,
      iconKey: null,
      colorArgb: null),
  FinanceCategory(
      id: 'dinner',
      name: 'Jantar fora',
      type: CategoryType.expense,
      parentId: 'food',
      isArchived: false,
      iconKey: null,
      colorArgb: null),
  FinanceCategory(
      id: 'lunch',
      name: 'Almoço fora',
      type: CategoryType.expense,
      parentId: 'food',
      isArchived: false,
      iconKey: null,
      colorArgb: null),
  FinanceCategory(
      id: 'pay',
      name: 'Salário',
      type: CategoryType.income,
      parentId: null,
      isArchived: false,
      iconKey: null,
      colorArgb: null),
];

class History implements CategoryHistoryRepository {
  Future<Map<String, String>>? delayed;
  final types = <TransactionType>[];
  @override
  Future<Map<String, String>> load(TransactionType type) {
    types.add(type);
    return delayed ??
        Future.value(type == TransactionType.expense
            ? {'jantar': 'dinner', 'almoço': 'lunch'}
            : {'jantar': 'pay'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late History history;
  setUp(() async {
    await getIt.reset();
    history = History();
    getIt.registerSingleton<CategoryHistoryRepository>(history);
  });
  tearDown(() => getIt.reset());
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField).first, text);
    await tester.pumpAndSettle();
  }

  String? value(WidgetTester tester, String key) =>
      tester.state<FormFieldState<String>>(find.byKey(ValueKey(key))).value;
  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets(
        'sugere pai/filha, troca filha e limpa descrição desconhecida $platform',
        (tester) async {
      await forms.open(
          tester,
          const TransactionForm(
              accounts: series.accounts,
              categories: categories,
              fixedType: TransactionType.expense),
          platform: platform);
      await type(tester, '  JANTAR  ');
      expect(value(tester, 'category-expense-food'), 'food');
      expect(value(tester, 'subcategory-expense-food-dinner'), 'dinner');
      expect(find.text('Categoria preenchida pelo histórico.'), findsOneWidget);
      await type(tester, 'Almoço');
      expect(value(tester, 'subcategory-expense-food-lunch'), 'lunch');
      await type(tester, 'Novo');
      expect(value(tester, 'category-expense-null'), isNull);
      expect(find.text('Categoria preenchida pelo histórico.'), findsNothing);
    });
  }
  testWidgets(
      'escolha manual Sem categoria vence a próxima descrição e resposta atrasada',
      (tester) async {
    final completer = Completer<Map<String, String>>();
    history.delayed = completer.future;
    await forms.open(
        tester,
        const TransactionForm(
            accounts: series.accounts,
            categories: categories,
            fixedType: TransactionType.expense));
    await type(tester, 'Jantar');
    await series.select(tester, 'category-expense-null', 'Sem categoria');
    completer.complete({'jantar': 'dinner', 'almoço': 'lunch'});
    await tester.pumpAndSettle();
    await type(tester, 'Almoço');
    expect(value(tester, 'category-expense-null'), anyOf(isNull, ''));
    expect(find.text('Categoria preenchida pelo histórico.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('receita usa apenas classificação de receita', (tester) async {
    await forms.open(
        tester,
        const TransactionForm(
            accounts: series.accounts,
            categories: categories,
            fixedType: TransactionType.income,
            initialType: TransactionType.income));
    await type(tester, 'Jantar');
    expect(value(tester, 'category-income-pay'), 'pay');
    expect(history.types, [TransactionType.income]);
  });
  testWidgets('editar preserva categoria e não consulta histórico',
      (tester) async {
    final item = FinancialTransaction(
        id: 'a',
        description: 'Antes',
        type: TransactionType.expense,
        amountMinor: 1000,
        date: DateTime.now(),
        isEffective: false,
        accountId: 'a',
        accountName: 'Banco',
        categoryId: 'lunch',
        categoryName: 'Almoço fora',
        currencyCode: 'BRL');
    await forms.open(
        tester,
        TransactionForm(
            accounts: series.accounts, categories: categories, item: item));
    await type(tester, 'Jantar');
    expect(value(tester, 'subcategory-expense-food-lunch'), 'lunch');
    expect(history.types, isEmpty);
  });
  testWidgets('sugestão salva subcategoria sem mudar os demais campos',
      (tester) async {
    Object? saved;
    await forms.open(
        tester,
        const TransactionForm(
            accounts: series.accounts,
            categories: categories,
            fixedType: TransactionType.expense),
        onResult: (draft) => saved = draft);
    await type(tester, 'Jantar');
    forms.field(tester, 1).controller!.text = '15,00';
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pumpAndSettle();
    final draft = saved as TransactionDraft;
    expect(draft.categoryId, 'dinner');
    expect(draft.amountMinor, 1500);
    expect(draft.accountId, 'a');
    expect(draft.isEffective, true);
  });
}
