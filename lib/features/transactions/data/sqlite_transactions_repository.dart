import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/entity_metadata.dart';
import '../domain/financial_transaction.dart';
import '../domain/transactions_repository.dart';

class SqliteTransactionsRepository implements TransactionsRepository {
  const SqliteTransactionsRepository(this._db);
  final AppDatabase _db;

  static const _select = '''
    SELECT t.id, t.description, t.type, t.planned_amount_minor,
      t.competence_at, t.effective_at, t.account_id, t.category_id,
      a.name AS account_name, a.currency_code,
      c.name AS category_name
    FROM transactions t
    JOIN accounts a ON a.id = t.account_id
    LEFT JOIN categories c ON c.id = t.category_id
  ''';

  @override
  Future<List<FinancialTransaction>> list([
    TransactionFilter filter = const TransactionFilter(),
  ]) async {
    final where = <String>['t.deleted_at IS NULL'];
    final variables = <Variable>[];
    if (filter.type != null) {
      where.add('t.type = ?');
      variables.add(Variable.withString(filter.type!.name));
    }
    if (filter.accountId != null) {
      where.add('t.account_id = ?');
      variables.add(Variable.withString(filter.accountId!));
    }
    if (filter.categoryId != null) {
      where.add('(t.category_id = ? OR c.parent_id = ?)');
      variables.add(Variable.withString(filter.categoryId!));
      variables.add(Variable.withString(filter.categoryId!));
    }
    switch (filter.status) {
      case TransactionStatus.effective:
        where.add('t.effective_at IS NOT NULL');
      case TransactionStatus.pending:
        where.add('t.effective_at IS NULL');
      case TransactionStatus.all:
        break;
    }
    if (filter.from != null) {
      where.add('t.competence_at >= ?');
      variables.add(Variable.withInt(_dayMillis(filter.from!)));
    }
    if (filter.to != null) {
      where.add('t.competence_at < ?');
      final day = DateTime.utc(filter.to!.year, filter.to!.month, filter.to!.day + 1);
      variables.add(Variable.withInt(day.millisecondsSinceEpoch));
    }
    final rows = await _db.customSelect('''
      $_select WHERE ${where.join(' AND ')}
      ORDER BY t.competence_at DESC, t.created_at DESC, t.id DESC
    ''', variables: variables).get();
    return rows.map(_map).toList();
  }

  @override
  Future<FinancialTransaction> create(TransactionDraft draft) async {
    _validateDraft(draft);
    await _validateReferences(draft);
    final id = EntityMetadata.newId();
    final now = EntityMetadata.nowUtcMillis();
    final day = _dayMillis(draft.date);
    await _db.customStatement('''
      INSERT INTO transactions
        (id, description, type, planned_amount_minor, actual_amount_minor,
         competence_at, effective_at, account_id, category_id,
         created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, draft.description.trim(), draft.type.name, draft.amountMinor,
      draft.isEffective ? draft.amountMinor : null, day,
      draft.isEffective ? day : null, draft.accountId, draft.categoryId,
      now, now]);
    return _find(id);
  }

  @override
  Future<FinancialTransaction> update(String id, TransactionDraft draft) async {
    _validateDraft(draft);
    final original = await _find(id);
    final accountChanged = original.accountId != draft.accountId;
    final categoryChanged = original.categoryId != draft.categoryId;
    final typeChanged = original.type != draft.type;
    if (accountChanged || categoryChanged || typeChanged) {
      await _validateReferences(draft, checkAccount: accountChanged,
          checkCategory: categoryChanged || typeChanged);
    }
    // Não revalida conta/categoria arquivada ao editar só descrição, data ou
    // valor de um lançamento histórico; mudar o vínculo exige entidade ativa.
    final fields = <String>[
      'description = ?', 'planned_amount_minor = ?', 'actual_amount_minor = ?',
      'competence_at = ?', 'effective_at = ?', 'updated_at = ?',
      'sync_version = sync_version + 1',
    ];
    final day = _dayMillis(draft.date);
    final args = <Object?>[
      draft.description.trim(), draft.amountMinor,
      draft.isEffective ? draft.amountMinor : null, day,
      draft.isEffective ? day : null, EntityMetadata.nowUtcMillis(),
    ];
    if (accountChanged) {
      fields.add('account_id = ?');
      args.add(draft.accountId);
    }
    if (categoryChanged) {
      fields.add('category_id = ?');
      args.add(draft.categoryId);
    }
    if (typeChanged) {
      fields.add('type = ?');
      args.add(draft.type.name);
    }
    args.add(id);
    await _db.customStatement('''
      UPDATE transactions SET ${fields.join(', ')}
      WHERE id = ? AND deleted_at IS NULL
    ''', args);
    return _find(id);
  }

  @override
  Future<void> delete(String id) async {
    await _find(id);
    final now = EntityMetadata.nowUtcMillis();
    await _db.customStatement('''
      UPDATE transactions SET deleted_at = ?, updated_at = ?,
        sync_version = sync_version + 1
      WHERE id = ? AND deleted_at IS NULL
    ''', [now, now, id]);
  }

  @override
  Future<void> setEffective(String id, {required bool effective}) async {
    // Mantém a data de competência, o valor e os vínculos do lançamento.
    // O corte por competência continua coerente com a edição pelo formulário.
    final changed = await _db.customUpdate('''
      UPDATE transactions
      SET effective_at = ${effective ? 'competence_at' : 'NULL'},
        actual_amount_minor = ${effective ? 'planned_amount_minor' : 'NULL'},
        updated_at = ?, sync_version = sync_version + 1
      WHERE id = ? AND deleted_at IS NULL
        AND effective_at IS ${effective ? 'NULL' : 'NOT NULL'}
    ''', variables: [Variable.withInt(EntityMetadata.nowUtcMillis()),
      Variable.withString(id)]);
    if (changed != 1) {
      throw StateError('O lançamento já mudou de estado. Atualize a lista.');
    }
  }

  Future<FinancialTransaction> _find(String id) async {
    final rows = await _db.customSelect('''
      $_select WHERE t.id = ? AND t.deleted_at IS NULL
    ''', variables: [Variable.withString(id)]).get();
    if (rows.isEmpty) throw StateError('Lançamento não encontrado.');
    return _map(rows.single);
  }

  Future<void> _validateReferences(TransactionDraft draft,
      {bool checkAccount = true, bool checkCategory = true}) async {
    if (checkAccount) {
      final account = await _db.customSelect('''
        SELECT id FROM accounts WHERE id = ? AND deleted_at IS NULL
          AND is_archived = 0
      ''', variables: [Variable.withString(draft.accountId)]).get();
      if (account.isEmpty) throw StateError('Selecione uma conta ativa.');
    }
    if (!checkCategory || draft.categoryId == null) return;
    final category = await _db.customSelect('''
      SELECT c.id FROM categories c
      LEFT JOIN categories p ON p.id = c.parent_id
      WHERE c.id = ? AND c.type = ? AND c.deleted_at IS NULL
        AND c.is_archived = 0
        AND (c.parent_id IS NULL OR (p.is_archived = 0 AND p.deleted_at IS NULL))
    ''', variables: [Variable.withString(draft.categoryId!),
      Variable.withString(draft.type.name)]).get();
    if (category.isEmpty) {
      throw StateError('Selecione uma categoria ativa do mesmo tipo.');
    }
  }

  void _validateDraft(TransactionDraft draft) {
    if (draft.description.trim().isEmpty) {
      throw const FormatException('Informe a descrição.');
    }
    if (draft.amountMinor <= 0) {
      throw const FormatException('O valor deve ser maior que zero.');
    }
    if (draft.amountMinor > 9000000000000000) {
      throw const FormatException('Valor acima do limite permitido.');
    }
    if (draft.accountId.isEmpty) throw StateError('Selecione uma conta.');
  }

  int _dayMillis(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch;

  FinancialTransaction _map(QueryRow row) => FinancialTransaction(
        id: row.read<String>('id'),
        description: row.read<String>('description'),
        type: TransactionType.values.byName(row.read<String>('type')),
        amountMinor: row.read<int>('planned_amount_minor'),
        date: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('competence_at'), isUtc: true,
        ),
        isEffective: row.readNullable<int>('effective_at') != null,
        accountId: row.read<String>('account_id'),
        accountName: row.read<String>('account_name'),
        categoryId: row.readNullable<String>('category_id'),
        categoryName: row.readNullable<String>('category_name'),
        currencyCode: row.read<String>('currency_code'),
      );
}
