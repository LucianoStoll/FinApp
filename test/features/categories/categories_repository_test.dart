import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/core/database/schema_v1.dart';
import 'package:finapp/core/database/schema_v2.dart';
import 'package:finapp/features/accounts/data/sqlite_accounts_repository.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/categories/data/sqlite_categories_repository.dart';
import 'package:finapp/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

class _LegacyV2 extends GeneratedDatabase {
  _LegacyV2(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {
          for (final statement in [...schemaV1, ...schemaV2]) {
            await customStatement(statement);
          }
        },
      );
}

void main() {
  test('hierarquia, CRUD e arquivamento preservam histórico', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SqliteCategoriesRepository(db);
    final account = await SqliteAccountsRepository(db).create(const AccountDraft(
      name: 'Carteira', type: AccountType.cash, currencyCode: 'BRL',
      initialBalanceMinor: 0, includeInAnalytics: true,
    ));
    final parent = await repo.create(const CategoryDraft(
      name: 'Alimentação', type: CategoryType.expense,
      iconKey: 'food', colorArgb: 0xff388e3c,
    ));
    final child = await repo.create(CategoryDraft(
      name: 'Restaurante', type: CategoryType.expense, parentId: parent.id,
    ));
    expect(child.parentId, parent.id);
    expect(parent.iconKey, 'food');
    expect(parent.colorArgb, 0xff388e3c);
    final edited = await repo.update(child.id, CategoryDraft(
      name: 'Jantar fora', type: CategoryType.expense, parentId: parent.id,
      iconKey: 'food',
    ));
    expect(edited.name, 'Jantar fora');
    await expectLater(
      repo.create(CategoryDraft(name: 'Salário', type: CategoryType.income,
        parentId: parent.id)),
      throwsA(isA<StateError>()),
    );

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    Future<void> insertTransaction(String id, String categoryId) =>
        db.customStatement('''INSERT INTO transactions
          (id, description, type, planned_amount_minor, competence_at,
           account_id, category_id, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [id, 'Almoço', 'expense', 1000, now, account.id, categoryId, now, now]);
    await insertTransaction('existing', child.id);
    await repo.setArchived(parent.id, archived: true);
    expect((await repo.list()).where((category) => category.isArchived).length, 2);
    final historical = await db.customSelect('''
      SELECT category_id FROM transactions WHERE id = ?
    ''', variables: [Variable.withString('existing')]).getSingle();
    expect(historical.read<String>('category_id'), child.id);
    await expectLater(insertTransaction('blocked', child.id),
      throwsA(isA<Exception>()));
    await repo.setArchived(parent.id, archived: false);
    await expectLater(repo.setArchived(child.id, archived: false), completes);
    await insertTransaction('new', child.id);
    expect((await db.customSelect('SELECT COUNT(*) AS total FROM transactions').getSingle())
        .read<int>('total'), 2);
  });

  test('migra base v2 com categorias e transações sem perder vínculos', () async {
    final directory = await Directory.systemTemp.createTemp('finapp-categories-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finapp.sqlite');
    final legacy = _LegacyV2(NativeDatabase(file));
    await legacy.customStatement('''INSERT INTO accounts
      (id, name, type, currency_code, initial_balance_minor,
       created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)''',
      ['account', 'Carteira', 'cash', 'BRL', 0, 1, 1]);
    await legacy.customStatement('''INSERT INTO categories
      (id, name, type, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)''', ['category', 'Lazer', 'expense', 1, 1]);
    await legacy.customStatement('''INSERT INTO transactions
      (id, description, type, planned_amount_minor, competence_at,
       account_id, category_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      ['transaction', 'Cinema', 'expense', 2000, 1,
        'account', 'category', 1, 1]);
    await legacy.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 4);
    final category = (await SqliteCategoriesRepository(db).list()).single;
    expect(category.id, 'category');
    expect(category.iconKey, isNull);
    final history = await db.customSelect('''
      SELECT category_id FROM transactions WHERE id = 'transaction'
    ''').getSingle();
    expect(history.read<String>('category_id'), category.id);
  });
}
