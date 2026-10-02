import 'package:finapp/core/series/movement_series.dart';
import 'package:finapp/core/di/injection.dart';
import 'package:finapp/core/theme/app_theme.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/accounts/domain/accounts_repository.dart';
import 'package:finapp/features/categories/domain/category.dart';
import 'package:finapp/features/categories/domain/categories_repository.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:finapp/features/transactions/domain/transactions_repository.dart';
import 'package:finapp/features/transactions/presentation/transactions_page.dart';
import 'package:finapp/features/transfers/domain/transfer.dart';
import 'package:finapp/features/transfers/domain/transfers_repository.dart';
import 'package:finapp/features/transfers/presentation/transfers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Accounts implements AccountsRepository {
  @override
  Future<List<Account>> list({DateTime? asOf, DateTime? through}) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoriesRepository {
  @override
  Future<List<FinanceCategory>> list() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionsRepository {
  _Transactions(this.type, {this.scheduled = false});
  final TransactionType type;
  final bool scheduled;
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime? changed;
  bool hasChanged = false;
  int writes = 0;
  int amount = 12345;
  @override
  Future<void> updateAmount(String id,
      {required int expectedAmountMinor,
      required int amountMinor,
      SeriesScope scope = SeriesScope.onlyThis}) async {
    expect(amount, expectedAmountMinor);
    amount = amountMinor;
  }

  DateTime? get date => hasChanged
      ? changed
      : scheduled
          ? today.add(const Duration(days: 5))
          : null;
  @override
  Future<List<FinancialTransaction>> list(
          [TransactionFilter filter = const TransactionFilter()]) async =>
      [
        FinancialTransaction(
            id: 'a',
            description: 'Teste',
            type: type,
            amountMinor: amount,
            date: today.subtract(const Duration(days: 2)),
            dueDate: today.add(const Duration(days: 5)),
            effectiveDate: date,
            isEffective: date != null && !date!.isAfter(today),
            accountId: 'bank',
            accountName: 'Banco',
            categoryId: null,
            categoryName: null,
            currencyCode: 'BRL')
      ];
  @override
  Future<void> setEffective(String id,
      {required bool effective, DateTime? effectiveDate}) async {
    writes++;
    hasChanged = true;
    changed = effective ? effectiveDate : null;
  }

  @override
  Future<void> changeEffectiveDate(String id,
      {required DateTime expectedDate, DateTime? effectiveDate}) async {
    expect(DateUtils.isSameDay(date, expectedDate), true);
    writes++;
    hasChanged = true;
    changed = effectiveDate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transfers implements TransfersRepository {
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime? date;
  int writes = 0;
  int amount = 12345;
  @override
  Future<void> updateAmount(String id,
      {required int expectedAmountMinor,
      required int amountMinor,
      SeriesScope scope = SeriesScope.onlyThis}) async {
    expect(amount, expectedAmountMinor);
    amount = amountMinor;
  }

  @override
  Future<List<Transfer>> list({String? accountId}) async => [
        Transfer(
            id: 'a',
            description: 'Reserva',
            sourceAccountId: 's',
            sourceAccountName: 'Origem',
            destinationAccountId: 'd',
            destinationAccountName: 'Destino',
            amountMinor: amount,
            currencyCode: 'BRL',
            date: today.subtract(const Duration(days: 2)),
            dueDate: today.add(const Duration(days: 5)),
            effectiveDate: date,
            isEffective: date != null && !date!.isAfter(today))
      ];
  @override
  Future<void> setEffective(String id,
      {required bool effective, DateTime? effectiveDate}) async {
    writes++;
    date = effective ? effectiveDate : null;
  }

  @override
  Future<void> changeEffectiveDate(String id,
      {required DateTime expectedDate, DateTime? effectiveDate}) async {
    expect(DateUtils.isSameDay(date, expectedDate), true);
    writes++;
    date = effectiveDate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> open(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: page));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<AccountsRepository>(_Accounts());
    getIt.registerSingleton<CategoriesRepository>(_Categories());
  });
  tearDown(() => getIt.reset());
  for (final type in TransactionType.values) {
    for (final scheduled in [false, true]) {
      testWidgets('$type agendado=$scheduled: hoje, desfazer', (tester) async {
        final repo = _Transactions(type, scheduled: scheduled);
        final original = (await repo.list()).single;
        getIt.registerSingleton<TransactionsRepository>(repo);
        await open(tester, TransactionsPage(sectionType: type));
        await tester.tap(find.byKey(const ValueKey('movement-status-a')));
        await tester.pumpAndSettle();
        expect(DateUtils.isSameDay(repo.date, repo.today), true);
        expect(find.text('Desfazer'), findsOneWidget);
        expect(find.text('Ajustar data'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.writes, 1);
        await tester.tap(find.text('Desfazer'));
        await tester.pumpAndSettle();
        expect(repo.date, original.effectiveDate);
        final undone = (await repo.list()).single;
        expect(undone.amountMinor, original.amountMinor);
        expect(undone.date, original.date);
        expect(undone.dueDate, original.dueDate);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final type in TransactionType.values) {
    testWidgets('$type: ícone permite remover efetivação após feedback expirar',
        (tester) async {
      final repo = _Transactions(type);
      getIt.registerSingleton<TransactionsRepository>(repo);
      await open(tester, TransactionsPage(sectionType: type));
      await tester.tap(find.byKey(const ValueKey('movement-status-a')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Desfazer'), findsNothing);
      expect(find.text('Ajustar data'), findsNothing);
      expect(find.byTooltip('Marcar como pendente'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('movement-status-a')));
      await tester.pumpAndSettle();
      expect(repo.date, isNull);
      expect(repo.writes, 2);
      expect((await repo.list()).single.amountMinor, 12345);
    });
  }
  for (final movement in ['income', 'expense', 'transfer']) {
    for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
      testWidgets(
          '$movement $platform: valor abre calculadora, confirma e cancela',
          (tester) async {
        final transactions = _Transactions(movement == 'income'
            ? TransactionType.income
            : TransactionType.expense);
        final transfers = _Transfers();
        getIt.registerSingleton<TransactionsRepository>(transactions);
        getIt.registerSingleton<TransfersRepository>(transfers);
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final page = movement == 'transfer'
            ? const TransfersPage()
            : TransactionsPage(sectionType: transactions.type);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.dark.copyWith(platform: platform), home: page));
        await tester.pumpAndSettle();
        Future<void> openCalculator() async {
          await tester.tap(find.byKey(const ValueKey('movement-amount-a')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text('Calculadora'), findsOneWidget);
          expect(find.text('123,45'), findsOneWidget);
          expect(find.byType(TransactionForm), findsNothing);
          expect(find.byType(TransferForm), findsNothing);
        }

        Future<void> press(String key) async {
          await tester.tap(find.byKey(ValueKey('calculator-key-$key')));
          await tester.pump();
        }

        int amount() =>
            movement == 'transfer' ? transfers.amount : transactions.amount;
        await openCalculator();
        await press('9');
        await tester.tap(find.byTooltip('Cancelar'));
        await tester.pumpAndSettle();
        expect(amount(), 12345);
        await openCalculator();
        await press('8');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(amount(), 12345);
        await openCalculator();
        await press('+');
        await press('1');
        await tester.tap(find.text('Confirmar valor'));
        await tester.pumpAndSettle();
        expect(amount(), 12445);
        expect(transactions.writes, 0);
        expect(transfers.writes, 0);
        expect(find.text('Calculadora'), findsNothing);
        expect(find.textContaining('124,45'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
      'transferência: ícone efetivado remove efetivação mesmo depois do feedback expirar',
      (tester) async {
    final repo = _Transfers();
    getIt.registerSingleton<TransfersRepository>(repo);
    await open(tester, const TransfersPage());
    final original = (await repo.list()).single;
    await tester.tap(find.byKey(const ValueKey('movement-status-a')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Desfazer'), findsNothing);
    expect(find.byTooltip('Marcar como pendente'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('movement-status-a')));
    await tester.pumpAndSettle();
    expect(repo.date, isNull);
    expect(repo.writes, 2);
    final pending = (await repo.list()).single;
    expect(pending.isEffective, false);
    expect(pending.amountMinor, original.amountMinor);
    expect(pending.sourceAccountId, original.sourceAccountId);
    expect(pending.destinationAccountId, original.destinationAccountId);
    expect(pending.dueDate, original.dueDate);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'transferência: efetivar, cancelar ajuste, ajustar pelo menu e desfazer',
      (tester) async {
    final repo = _Transfers();
    getIt.registerSingleton<TransfersRepository>(repo);
    await open(tester, const TransfersPage());
    await tester.tap(find.byKey(const ValueKey('movement-status-a')));
    await tester.pumpAndSettle();
    expect(DateUtils.isSameDay(repo.date, repo.today), true);
    await tester.tap(find.text('Ajustar data'));
    // A linha segue ocupada enquanto o seletor aguarda uma escolha.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    await tester.tap(find.byKey(const ValueKey('movement-menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustar data'));
    // A linha segue ocupada enquanto o seletor aguarda uma escolha.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(repo.writes, 2);
    await tester.tap(find.byKey(const ValueKey('movement-menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como pendente'));
    await tester.pumpAndSettle();
    expect(repo.date, isNull);
    await tester.tap(find.byKey(const ValueKey('movement-status-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(repo.date, isNull);
    expect(tester.takeException(), isNull);
  });
}
