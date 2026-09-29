import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/core/database/entity_metadata.dart';

void main() {
  test('v1 cria o schema e mantém integridade e valores inteiros', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 5);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    expect(
      tables.map((row) => row.read<String>('name')),
      containsAll(['accounts', 'categories', 'transactions', 'transfers']),
    );

    final now = EntityMetadata.nowUtcMillis();
    final accountId = EntityMetadata.newId();
    expect(accountId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    await db.customStatement(
      '''INSERT INTO accounts
         (id, name, type, currency_code, initial_balance_minor, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [accountId, 'Carteira', 'cash', 'BRL', 12345, now, now],
    );
    final balance = await db.customSelect(
      'SELECT initial_balance_minor FROM accounts WHERE id = ?',
      variables: [Variable.withString(accountId)],
    ).getSingle();
    expect(balance.read<int>('initial_balance_minor'), 12345);

    await expectLater(
      db.customStatement(
        '''INSERT INTO transactions
           (id, description, type, planned_amount_minor, competence_at,
            account_id, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          EntityMetadata.newId(),
          'Teste',
          'expense',
          100,
          now,
          EntityMetadata.newId(),
          now,
          now
        ],
      ),
      throwsA(isA<Exception>()),
    );
  });
}
