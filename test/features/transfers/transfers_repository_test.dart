import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/core/database/schema_v1.dart';
import 'package:finapp/core/database/schema_v2.dart';
import 'package:finapp/core/database/schema_v3.dart';
import 'package:finapp/features/accounts/data/sqlite_accounts_repository.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/transfers/data/sqlite_transfers_repository.dart';
import 'package:finapp/features/transfers/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

class _LegacyV3 extends GeneratedDatabase {
  _LegacyV3(super.executor);

  @override
  int get schemaVersion => 3;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {
        for (final statement in [...schemaV1, ...schemaV2, ...schemaV3]) {
          await customStatement(statement);
        }
      });
}

void main() {
  test('transferência movimenta duas contas, mantém patrimônio e persiste',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('finapp-transfers-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finapp.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    final accounts = SqliteAccountsRepository(db);
    final source = await accounts.create(const AccountDraft(
        name: 'Origem',
        type: AccountType.checking,
        currencyCode: 'BRL',
        initialBalanceMinor: 10000,
        includeInAnalytics: true));
    final destination = await accounts.create(const AccountDraft(
        name: 'Destino',
        type: AccountType.savings,
        currencyCode: 'BRL',
        initialBalanceMinor: 2000,
        includeInAnalytics: true));
    final transfers = SqliteTransfersRepository(db);
    final date = DateTime.utc(2026, 9, 29);
    final draft = TransferDraft(
        sourceAccountId: source.id,
        destinationAccountId: destination.id,
        amountMinor: 2500,
        date: date,
        isEffective: false);
    final pending = await transfers.create(draft);
    expect(pending.isEffective, isFalse);
    expect(pending.date, date);
    expect((await accounts.list()).map((a) => a.currentBalanceMinor).toList(),
        [2000, 10000]); // Ordenação alfabética: Destino, Origem.

    final paid = await transfers.update(
        pending.id,
        TransferDraft(
            sourceAccountId: source.id,
            destinationAccountId: destination.id,
            amountMinor: 2500,
            date: date,
            isEffective: true));
    expect(paid.isEffective, isTrue);
    final balances = {
      for (final a in await accounts.list()) a.id: a.currentBalanceMinor
    };
    expect(balances[source.id], 7500);
    expect(balances[destination.id], 4500);
    expect(balances.values.reduce((a, b) => a + b), 12000);
    expect((await transfers.list(accountId: source.id)).single.id, paid.id);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final restored = SqliteTransfersRepository(db);
    expect((await restored.list()).single.date, date);
    await restored.delete(paid.id);
    expect(await restored.list(), isEmpty);
    final finalBalances = {
      for (final a in await SqliteAccountsRepository(db).list())
        a.id: a.currentBalanceMinor
    };
    expect(finalBalances[source.id], 10000);
    expect(finalBalances[destination.id], 2000);
    final row = await db.customSelect('''
      SELECT deleted_at, source_account_id, destination_account_id
      FROM transfers WHERE id = ?
    ''', variables: [Variable.withString(paid.id)]).getSingle();
    expect(row.readNullable<int>('deleted_at'), isNotNull);
    expect(row.read<String>('source_account_id'), source.id);
    expect(row.read<String>('destination_account_id'), destination.id);
  });

  test(
      'contas iguais, moedas distintas e contas arquivadas não criam movimento',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = SqliteAccountsRepository(db);
    Future<Account> add(String name, String currency) =>
        accounts.create(AccountDraft(
            name: name,
            type: AccountType.cash,
            currencyCode: currency,
            initialBalanceMinor: 0,
            includeInAnalytics: true));
    final a = await add('A', 'BRL');
    final b = await add('B', 'BRL');
    final usd = await add('USD', 'USD');
    final repo = SqliteTransfersRepository(db);
    final date = DateTime.utc(2026, 10, 1);
    TransferDraft draft(String source, String dest) => TransferDraft(
        sourceAccountId: source,
        destinationAccountId: dest,
        amountMinor: 100,
        date: date,
        isEffective: true);
    await expectLater(
        repo.create(draft(a.id, a.id)), throwsA(isA<StateError>()));
    await expectLater(
        repo.create(draft(a.id, usd.id)), throwsA(isA<StateError>()));
    final saved = await repo.create(draft(a.id, b.id));
    await accounts.setArchived(b.id, archived: true);
    await expectLater(
        repo.create(draft(a.id, b.id)), throwsA(isA<StateError>()));
    // Editar o histórico não exige reativar a conta já vinculada.
    await repo.update(
        saved.id,
        TransferDraft(
            sourceAccountId: a.id,
            destinationAccountId: b.id,
            amountMinor: 200,
            date: date,
            isEffective: true));
    expect((await repo.list()).single.amountMinor, 200);
    expect(
        (await accounts.list())
            .map((a) => a.currentBalanceMinor)
            .reduce((a, b) => a + b),
        0);
    expect(
        await db
            .customSelect('SELECT COUNT(*) AS total FROM transactions')
            .getSingle()
            .then((r) => r.read<int>('total')),
        0);
  });

  test('migração v3 preserva transferência antiga e preenche data planejada',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('finapp-transfer-migration-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finapp.sqlite');
    final legacy = _LegacyV3(NativeDatabase(file));
    for (final id in ['a', 'b']) {
      await legacy.customStatement('''INSERT INTO accounts
        (id, name, type, currency_code, initial_balance_minor, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)''', [id, id, 'cash', 'BRL', 0, 1, 1]);
    }
    await legacy.customStatement('''INSERT INTO transfers
      (id, source_account_id, destination_account_id, amount_minor,
       effective_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)''',
        ['old', 'a', 'b', 500, null, 1000, 1000]);
    await legacy.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        6);
    final old = (await SqliteTransfersRepository(db).list()).single;
    expect(old.id, 'old');
    expect(old.amountMinor, 500);
    expect(old.date.millisecondsSinceEpoch, 1000);
    expect(old.isEffective, isFalse);
  });
}
