import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/features/accounts/data/sqlite_accounts_repository.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/dashboard/data/sqlite_dashboard_repository.dart';
import 'package:finapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:finapp/features/transactions/data/sqlite_transactions_repository.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:finapp/features/transfers/data/sqlite_transfers_repository.dart';
import 'package:finapp/features/transfers/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resumo mensal atualiza após operações locais sem reiniciar', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = SqliteAccountsRepository(db);
    Future<Account> account(String name, String currency,
        {bool analytics = true}) => accounts.create(AccountDraft(
      name: name, type: AccountType.checking, currencyCode: currency,
      initialBalanceMinor: 10000, includeInAnalytics: analytics));
    final bank = await account('Banco', 'BRL');
    final wallet = await account('Carteira', 'BRL', analytics: false);
    final usd = await account('Exterior', 'USD');
    final transactions = SqliteTransactionsRepository(db);
    final transfers = SqliteTransfersRepository(db);
    final dashboard = SqliteDashboardRepository(db);
    final september = DateTime.utc(2026, 9, 12);
    final october = DateTime.utc(2026, 10, 1);

    Future<FinancialTransaction> move(TransactionType type, int amount,
      DateTime date, {String? accountId, bool effective = true}) =>
      transactions.create(TransactionDraft(description: 'Lançamento',
        type: type, amountMinor: amount, date: date, isEffective: effective,
        accountId: accountId ?? bank.id));

    final initial = await dashboard.load(september);
    expect(initial.currencies.length, 2);
    expect(initial.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .currentBalanceMinor, 20000);
    expect(initial.currencies.firstWhere((x) => x.currencyCode == usd.currencyCode)
      .currentBalanceMinor, 10000);
    expect(initial.recent, isEmpty);
    final income = await move(TransactionType.income, 5000, september);
    final expense = await move(TransactionType.expense, 1000, september);
    await move(TransactionType.income, 700, september,
      accountId: wallet.id); // Conta fora das análises, mas dentro do saldo.
    await move(TransactionType.expense, 300, october);
    await move(TransactionType.expense, 600, september, effective: false);
    final transfer = await transfers.create(TransferDraft(
      sourceAccountId: bank.id, destinationAccountId: wallet.id,
      amountMinor: 2000, date: september, isEffective: true));
    await db.customStatement('UPDATE transfers SET created_at = ? WHERE id = ?',
      [DateTime.utc(2030).millisecondsSinceEpoch, transfer.id]);

    final updated = await dashboard.load(september);
    final brl = updated.currencies.firstWhere((x) => x.currencyCode == 'BRL');
    expect(brl.incomeMinor, 5000);
    expect(brl.expenseMinor, 1000);
    expect(brl.monthlyResultMinor, 4000);
    expect(brl.expensesByCategory.single.name, 'Sem categoria');
    expect(brl.expensesByCategory.single.amountMinor, 1000);
    expect(brl.currentBalanceMinor, 24700);
    expect(brl.projectedBalanceMinor, 24100);
    expect(updated.currencies.firstWhere((x) => x.currencyCode == 'USD')
      .currentBalanceMinor, 10000);
    expect(updated.recent.length, 5);
    expect(updated.recent.any((x) => x.id == transfer.id &&
      x.type == DashboardActivityType.transfer), isTrue);
    final next = await dashboard.load(october);
    expect(next.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .expenseMinor, 300);
    expect(next.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .currentBalanceMinor, 24400);

    await db.customStatement('UPDATE transactions SET ignore_analytics = 1 WHERE id = ?',
      [expense.id]);
    final hidden = await dashboard.load(september);
    expect(hidden.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .expenseMinor, 0);
    expect(hidden.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .expensesByCategory, isEmpty);
    expect(hidden.currencies.firstWhere((x) => x.currencyCode == 'BRL')
      .currentBalanceMinor, 24700);

    await transactions.delete(income.id);
    await transfers.delete(transfer.id);
    final afterDelete = await dashboard.load(september);
    final afterBrl = afterDelete.currencies.firstWhere((x) => x.currencyCode == 'BRL');
    expect(afterBrl.incomeMinor, 0);
    expect(afterBrl.currentBalanceMinor, 19700);
    expect(afterDelete.recent.any((x) => x.id == income.id ||
      x.id == transfer.id), isFalse);
  });

  test('despesa de dezembro não altera saldos de outubro', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final account = await SqliteAccountsRepository(db).create(const AccountDraft(
      name: 'Conta', type: AccountType.checking, currencyCode: 'BRL',
      initialBalanceMinor: 10000, includeInAnalytics: true));
    final transactions = SqliteTransactionsRepository(db);
    final october = DateTime.utc(2026, 10, 15);
    final december = DateTime.utc(2026, 12, 5);
    Future<void> add(TransactionType type, int amount, DateTime date,
        {bool effective = true}) async {
      await transactions.create(TransactionDraft(description: 'Teste', type: type,
        amountMinor: amount, date: date, isEffective: effective,
        accountId: account.id));
    }
    await add(TransactionType.income, 1000, october);
    await add(TransactionType.expense, 20000, december);
    await add(TransactionType.expense, 4000, december, effective: false);

    final dashboard = SqliteDashboardRepository(db);
    final oct = (await dashboard.load(october)).currencies.single;
    expect(oct.currentBalanceMinor, 11000);
    expect(oct.projectedBalanceMinor, 11000);
    final dec = (await dashboard.load(december)).currencies.single;
    expect(dec.currentBalanceMinor, -9000);
    expect(dec.projectedBalanceMinor, -13000);
    // A listagem da conta continua exibindo o saldo atual sem corte mensal.
    expect((await SqliteAccountsRepository(db).list()).single.currentBalanceMinor,
      -9000);
  });
}
