import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/features/accounts/data/sqlite_accounts_repository.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/balances/data/sqlite_balances_repository.dart';
import 'package:finapp/features/transactions/data/sqlite_transactions_repository.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:finapp/features/transfers/data/sqlite_transfers_repository.dart';
import 'package:finapp/features/transfers/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saldo por conta e consolidado considera efetivos, pendentes e prazo', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = SqliteAccountsRepository(db);
    Future<Account> add(String name, String currency, int initial) =>
        accounts.create(AccountDraft(name: name, type: AccountType.checking,
          currencyCode: currency, initialBalanceMinor: initial,
          includeInAnalytics: true));
    final bank = await add('Banco', 'BRL', 10000);
    final cash = await add('Carteira', 'BRL', 2000);
    final dollar = await add('Dólar', 'USD', 500);
    final transactions = SqliteTransactionsRepository(db);
    final transfers = SqliteTransfersRepository(db);
    final today = DateTime.utc(2026, 9, 29);
    final future = DateTime.utc(2026, 10, 15);
    TransactionDraft draft(String account, TransactionType type, int amount,
      DateTime date, bool effective) => TransactionDraft(description: 'Movimento',
        type: type, amountMinor: amount, date: date,
        isEffective: effective, accountId: account);

    await transactions.create(draft(bank.id, TransactionType.income, 4000, today, true));
    final expense = await transactions.create(
      draft(bank.id, TransactionType.expense, 1000, today, true));
    await transactions.create(draft(bank.id, TransactionType.expense, 1500, future, false));
    await transactions.create(draft(cash.id, TransactionType.income, 300, today, false));
    final paidTransfer = await transfers.create(TransferDraft(
      sourceAccountId: bank.id, destinationAccountId: cash.id,
      amountMinor: 2000, date: today, isEffective: true));
    await transfers.create(TransferDraft(sourceAccountId: cash.id,
      destinationAccountId: bank.id, amountMinor: 500,
      date: future, isEffective: false));

    final repo = SqliteBalancesRepository(db);
    final todaySnapshot = await repo.calculate(through: today);
    final todayById = {for (final a in todaySnapshot.accounts) a.accountId: a};
    expect(todayById[bank.id]!.currentMinor, 11000);
    expect(todayById[bank.id]!.projectedMinor, 11000);
    expect(todayById[cash.id]!.currentMinor, 4000);
    expect(todayById[cash.id]!.projectedMinor, 4300);
    expect(todaySnapshot.consolidated.singleWhere((a) => a.currencyCode == 'BRL')
      .currentMinor, 15000);

    final all = await repo.calculate();
    final byId = {for (final a in all.accounts) a.accountId: a};
    expect(byId[bank.id]!.projectedMinor, 10000);
    expect(byId[cash.id]!.projectedMinor, 3800);
    expect(all.consolidated.singleWhere((a) => a.currencyCode == 'BRL')
      .projectedMinor, 13800);
    expect(all.consolidated.singleWhere((a) => a.currencyCode == 'USD')
      .projectedMinor, 500);
    expect((await accounts.list()).firstWhere((a) => a.id == bank.id)
      .projectedBalanceMinor, 10000);

    // A flag de saldo independe da flag de análises.
    await db.customStatement('UPDATE transactions SET ignore_balance = 1 WHERE id = ?',
      [expense.id]);
    expect((await repo.calculate()).consolidated
      .singleWhere((a) => a.currencyCode == 'BRL').currentMinor, 16000);
    await transfers.delete(paidTransfer.id);
    final afterDelete = await repo.calculate();
    expect(afterDelete.accounts.firstWhere((a) => a.accountId == bank.id)
      .currentMinor, 14000);
    expect(afterDelete.consolidated.singleWhere((a) => a.currencyCode == 'BRL')
      .currentMinor, 16000);
    await accounts.setArchived(cash.id, archived: true);
    expect((await repo.calculate()).consolidated
      .singleWhere((a) => a.currencyCode == 'BRL').currentMinor, 16000);
    expect((await db.customSelect('SELECT COUNT(*) AS count FROM transactions')
      .getSingle()).read<int>('count'), 4);
  });
}
