import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:finapp/core/database/app_database.dart';
import 'package:finapp/features/accounts/data/sqlite_accounts_repository.dart';
import 'package:finapp/features/accounts/domain/account.dart';
import 'package:finapp/features/categories/data/sqlite_categories_repository.dart';
import 'package:finapp/features/categories/domain/category.dart';
import 'package:finapp/features/transactions/data/sqlite_transactions_repository.dart';
import 'package:finapp/features/transactions/domain/financial_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('efetivar na lista atualiza saldo e permite desfazer sem editar campos',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = SqliteAccountsRepository(db);
    final account = await accounts.create(const AccountDraft(
        name: 'Carteira',
        type: AccountType.cash,
        currencyCode: 'BRL',
        initialBalanceMinor: 5000,
        includeInAnalytics: true));
    final categories = SqliteCategoriesRepository(db);
    final category = await categories.create(
        const CategoryDraft(name: 'Mercado', type: CategoryType.expense));
    final repo = SqliteTransactionsRepository(db);
    final date = DateTime.utc(2026, 9, 28);
    final pending = await repo.create(TransactionDraft(
        description: 'Compra',
        type: TransactionType.expense,
        amountMinor: 1200,
        date: date,
        isEffective: false,
        accountId: account.id,
        categoryId: category.id));
    await categories.setArchived(category.id, archived: true);
    await accounts.setArchived(account.id, archived: true);
    await repo.setEffective(pending.id, effective: true);
    final effective = (await repo.list()).single;
    expect(effective.isEffective, isTrue);
    expect(effective.date, date);
    expect(effective.categoryId, category.id);
    expect(effective.amountMinor, 1200);
    expect((await accounts.list()).single.currentBalanceMinor, 3800);
    await expectLater(repo.setEffective(pending.id, effective: true),
        throwsA(isA<StateError>()));
    await repo.setEffective(pending.id, effective: false);
    expect((await accounts.list()).single.currentBalanceMinor, 5000);
    expect((await repo.list()).single.isEffective, isFalse);
  });

  test('receita/despesa, pendência, edição, filtros e exclusão lógica',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('finapp-transactions-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/finapp.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    final accounts = SqliteAccountsRepository(db);
    final account = await accounts.create(const AccountDraft(
      name: 'Conta corrente',
      type: AccountType.checking,
      currencyCode: 'BRL',
      initialBalanceMinor: 10000,
      includeInAnalytics: true,
    ));
    final categories = SqliteCategoriesRepository(db);
    final root = await categories.create(const CategoryDraft(
      name: 'Alimentação',
      type: CategoryType.expense,
    ));
    final child = await categories.create(CategoryDraft(
      name: 'Restaurante',
      type: CategoryType.expense,
      parentId: root.id,
    ));
    final repo = SqliteTransactionsRepository(db);
    final date = DateTime.utc(2026, 9, 28);
    final paid = await repo.create(TransactionDraft(
      description: 'Jantar',
      type: TransactionType.expense,
      amountMinor: 2500,
      date: date,
      isEffective: true,
      accountId: account.id,
      categoryId: child.id,
    ));
    expect((await accounts.list()).single.currentBalanceMinor, 7500);
    final pending = await repo.create(TransactionDraft(
      description: 'Salário',
      type: TransactionType.income,
      amountMinor: 50000,
      date: date,
      isEffective: false,
      accountId: account.id,
    ));
    expect((await accounts.list()).single.currentBalanceMinor, 7500);
    expect(
        (await repo.list(
                const TransactionFilter(status: TransactionStatus.pending)))
            .single
            .id,
        pending.id);
    expect((await repo.list(TransactionFilter(categoryId: root.id))).single.id,
        paid.id);
    expect(
        (await repo.list(TransactionFilter(from: date, to: date))).length, 2);
    await repo.update(
        pending.id,
        TransactionDraft(
          description: 'Salário recebido',
          type: TransactionType.income,
          amountMinor: 51000,
          date: date,
          isEffective: true,
          accountId: account.id,
        ));
    expect((await accounts.list()).single.currentBalanceMinor, 58500);
    expect(
        (await repo.list(
                const TransactionFilter(status: TransactionStatus.effective)))
            .length,
        2);
    await repo.delete(paid.id);
    expect((await repo.list()).length, 1);
    expect((await accounts.list()).single.currentBalanceMinor, 61000);
    final tombstone = await db.customSelect('''
      SELECT deleted_at, category_id FROM transactions WHERE id = ?
    ''', variables: [Variable.withString(paid.id)]).getSingle();
    expect(tombstone.readNullable<int>('deleted_at'), isNotNull);
    expect(tombstone.read<String>('category_id'), child.id);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(
        (await SqliteAccountsRepository(db).list()).single.currentBalanceMinor,
        61000);
    expect((await SqliteTransactionsRepository(db).list()).single.description,
        'Salário recebido');
  });

  test('arquivamento bloqueia novos vínculos e mantém edição do histórico',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = SqliteAccountsRepository(db);
    final account = await accounts.create(const AccountDraft(
      name: 'Carteira',
      type: AccountType.cash,
      currencyCode: 'BRL',
      initialBalanceMinor: 0,
      includeInAnalytics: true,
    ));
    final categories = SqliteCategoriesRepository(db);
    final category = await categories.create(const CategoryDraft(
      name: 'Mercado',
      type: CategoryType.expense,
    ));
    final repo = SqliteTransactionsRepository(db);
    final date = DateTime.utc(2026, 9, 28);
    final draft = TransactionDraft(
        description: 'Compras',
        type: TransactionType.expense,
        amountMinor: 1200,
        date: date,
        isEffective: true,
        accountId: account.id,
        categoryId: category.id);
    final existing = await repo.create(draft);
    await categories.setArchived(category.id, archived: true);
    await expectLater(repo.create(draft), throwsA(isA<StateError>()));
    final edited = await repo.update(
        existing.id,
        TransactionDraft(
          description: 'Compras editadas',
          type: TransactionType.expense,
          amountMinor: 1500,
          date: date,
          isEffective: true,
          accountId: account.id,
          categoryId: category.id,
        ));
    expect(edited.description, 'Compras editadas');
    expect((await accounts.list()).single.currentBalanceMinor, -1500);
    await accounts.setArchived(account.id, archived: true);
    await expectLater(
        repo.create(TransactionDraft(
          description: 'Novo',
          type: TransactionType.income,
          amountMinor: 100,
          date: date,
          isEffective: true,
          accountId: account.id,
        )),
        throwsA(isA<StateError>()));
    expect((await repo.list()).single.categoryId, category.id);
  });
}
