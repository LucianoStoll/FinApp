import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/core/database/schema_v1.dart';
import 'package:finapp/core/database/schema_v2.dart';
import 'package:finapp/core/database/schema_v3.dart';
import 'package:finapp/core/database/schema_v4.dart';
import 'package:finapp/features/transactions/data/sqlite_transactions_repository.dart';
import 'package:finapp/features/transfers/data/sqlite_transfers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _LegacyV4 extends GeneratedDatabase {
  _LegacyV4(super.executor);
  @override
  int get schemaVersion => 4;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {
        for (final statement in [
          ...schemaV1,
          ...schemaV2,
          ...schemaV3,
          ...schemaV4
        ]) {
          await customStatement(statement);
        }
      });
}

void main() {
  test('migração v4 preserva movimentos e preenche as datas de negócio',
      () async {
    final directory = await Directory.systemTemp.createTemp('somia-v5-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finapp.sqlite');
    final old = _LegacyV4(NativeDatabase(file));
    final posted = DateTime.utc(2026, 8, 1).millisecondsSinceEpoch;
    final paid = DateTime.utc(2026, 8, 3).millisecondsSinceEpoch;
    for (final id in ['a', 'b']) {
      await old.customStatement('''INSERT INTO accounts
        (id, name, type, currency_code, initial_balance_minor, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)''', [id, id, 'cash', 'BRL', 10000, 1, 1]);
    }
    await old.customStatement('''INSERT INTO transactions
      (id, description, type, planned_amount_minor, actual_amount_minor,
       competence_at, due_at, effective_at, account_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        ['tx', 'Legado', 'expense', 500, 500, posted, null, paid, 'a', 1, 1]);
    await old.customStatement('''INSERT INTO transfers
      (id, source_account_id, destination_account_id, amount_minor,
       planned_at, effective_at, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        ['tr', 'a', 'b', 200, posted, paid, 1, 1]);
    await old.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        AppDatabase.currentSchemaVersion);
    final transaction = (await SqliteTransactionsRepository(db).list()).single;
    final transfer = (await SqliteTransfersRepository(db).list()).single;
    expect(transaction.description, 'Legado');
    expect(transaction.date.millisecondsSinceEpoch, posted);
    expect(transaction.dueDate!.millisecondsSinceEpoch, posted);
    expect(transaction.effectiveDate!.millisecondsSinceEpoch, paid);
    expect(transfer.date.millisecondsSinceEpoch, posted);
    expect(transfer.dueDate!.millisecondsSinceEpoch, posted);
    expect(transfer.effectiveDate!.millisecondsSinceEpoch, paid);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
