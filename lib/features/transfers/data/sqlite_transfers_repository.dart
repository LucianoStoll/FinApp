import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/entity_metadata.dart';
import '../domain/transfer.dart';
import '../domain/transfers_repository.dart';

class SqliteTransfersRepository implements TransfersRepository {
  const SqliteTransfersRepository(this._db);

  final AppDatabase _db;

  static const _select = '''
    SELECT f.id, f.source_account_id, f.destination_account_id,
      f.amount_minor, f.posted_at, f.due_at, f.effective_at,
      source.name AS source_name, destination.name AS destination_name,
      source.currency_code AS currency_code
    FROM transfers f
    JOIN accounts source ON source.id = f.source_account_id
    JOIN accounts destination ON destination.id = f.destination_account_id
  ''';

  @override
  Future<List<Transfer>> list({String? accountId}) async {
    final rows = await _db.customSelect('''
      $_select WHERE f.deleted_at IS NULL
      ${accountId == null ? '' : 'AND (f.source_account_id = ? OR f.destination_account_id = ?)'}
      ORDER BY f.due_at DESC, f.id DESC
    ''', variables: accountId == null ? const [] : [
      Variable.withString(accountId), Variable.withString(accountId),
    ]).get();
    return rows.map(_map).toList();
  }

  @override
  Future<Transfer> create(TransferDraft draft) => _db.transaction(() async {
    _validateDraft(draft);
    await _validateAccounts(draft);
    final id = EntityMetadata.newId();
    final now = EntityMetadata.nowUtcMillis();
    await _db.customStatement('''
      INSERT INTO transfers (id, source_account_id, destination_account_id,
        amount_minor, planned_at, posted_at, due_at, effective_at,
        created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, draft.sourceAccountId, draft.destinationAccountId,
      draft.amountMinor, _dayMillis(draft.date), _dayMillis(draft.date),
      _dayMillis(draft.dueDate ?? draft.date),
      draft.isEffective ? _dayMillis(draft.effectiveDate ?? draft.date) : null,
      now, now]);
    return _find(id);
  });

  @override
  Future<Transfer> update(String id, TransferDraft draft) => _db.transaction(() async {
    _validateDraft(draft);
    final current = await _find(id);
    final sourceChanged = current.sourceAccountId != draft.sourceAccountId;
    final destinationChanged = current.destinationAccountId != draft.destinationAccountId;
    await _validateAccounts(draft,
      checkSource: sourceChanged, checkDestination: destinationChanged);
    final fields = <String>['amount_minor = ?', 'planned_at = ?',
      'posted_at = ?', 'due_at = ?', 'effective_at = ?', 'updated_at = ?',
      'sync_version = sync_version + 1'];
    final values = <Object?>[draft.amountMinor, _dayMillis(draft.date),
      _dayMillis(draft.date), _dayMillis(draft.dueDate ?? draft.date),
      draft.isEffective ? _dayMillis(draft.effectiveDate ?? draft.date) : null,
      EntityMetadata.nowUtcMillis()];
    if (sourceChanged) {
      fields.add('source_account_id = ?');
      values.add(draft.sourceAccountId);
    }
    if (destinationChanged) {
      fields.add('destination_account_id = ?');
      values.add(draft.destinationAccountId);
    }
    values.add(id);
    await _db.customStatement('''
      UPDATE transfers SET ${fields.join(', ')}
      WHERE id = ? AND deleted_at IS NULL
    ''', values);
    return _find(id);
  });

  @override
  Future<void> delete(String id) => _db.transaction(() async {
    await _find(id);
    final now = EntityMetadata.nowUtcMillis();
    await _db.customStatement('''
      UPDATE transfers SET deleted_at = ?, updated_at = ?,
        sync_version = sync_version + 1
      WHERE id = ? AND deleted_at IS NULL
    ''', [now, now, id]);
  });

  @override
  Future<void> setEffective(String id, {required bool effective,
      DateTime? effectiveDate}) async {
    final todayEnd = _dayMillis(DateTime.now().add(const Duration(days: 1)));
    final changed = await _db.customUpdate('''
      UPDATE transfers SET effective_at = ${effective ? '?' : 'NULL'},
        updated_at = ?, sync_version = sync_version + 1
      WHERE id = ? AND deleted_at IS NULL
        AND ${effective ? '(effective_at IS NULL OR effective_at >= ?)'
          : 'effective_at IS NOT NULL'}
    ''', variables: [
      if (effective) Variable.withInt(_dayMillis(effectiveDate ?? DateTime.now())),
      Variable.withInt(EntityMetadata.nowUtcMillis()), Variable.withString(id),
      if (effective) Variable.withInt(todayEnd),
    ]);
    if (changed != 1) {
      throw StateError('A transferência já mudou de estado. Atualize a lista.');
    }
  }

  Future<Transfer> _find(String id) async {
    final rows = await _db.customSelect('''
      $_select WHERE f.id = ? AND f.deleted_at IS NULL
    ''', variables: [Variable.withString(id)]).get();
    if (rows.isEmpty) throw StateError('Transferência não encontrada.');
    return _map(rows.single);
  }

  void _validateDraft(TransferDraft draft) {
    if (draft.sourceAccountId.isEmpty || draft.destinationAccountId.isEmpty) {
      throw StateError('Selecione as contas de origem e destino.');
    }
    if (draft.sourceAccountId == draft.destinationAccountId) {
      throw StateError('Selecione contas diferentes.');
    }
    if (draft.amountMinor <= 0 || draft.amountMinor > 9000000000000000) {
      throw const FormatException('Informe um valor maior que zero e dentro do limite.');
    }
  }

  Future<void> _validateAccounts(TransferDraft draft,
      {bool checkSource = true, bool checkDestination = true}) async {
    final rows = await _db.customSelect('''
      SELECT id, currency_code, is_archived, deleted_at FROM accounts
      WHERE id IN (?, ?)
    ''', variables: [Variable.withString(draft.sourceAccountId),
      Variable.withString(draft.destinationAccountId)]).get();
    if (rows.length != 2) throw StateError('Conta não encontrada.');
    final byId = {for (final row in rows) row.read<String>('id'): row};
    final source = byId[draft.sourceAccountId]!;
    final destination = byId[draft.destinationAccountId]!;
    if (checkSource && (source.read<int>('is_archived') == 1 ||
        source.readNullable<int>('deleted_at') != null)) {
      throw StateError('Selecione uma conta de origem ativa.');
    }
    if (checkDestination && (destination.read<int>('is_archived') == 1 ||
        destination.readNullable<int>('deleted_at') != null)) {
      throw StateError('Selecione uma conta de destino ativa.');
    }
    if (source.read<String>('currency_code') !=
        destination.read<String>('currency_code')) {
      throw StateError('As contas precisam ter a mesma moeda.');
    }
  }

  int _dayMillis(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch;

  Transfer _map(QueryRow row) => Transfer(
    id: row.read<String>('id'),
    sourceAccountId: row.read<String>('source_account_id'),
    sourceAccountName: row.read<String>('source_name'),
    destinationAccountId: row.read<String>('destination_account_id'),
    destinationAccountName: row.read<String>('destination_name'),
    currencyCode: row.read<String>('currency_code'),
    amountMinor: row.read<int>('amount_minor'),
    date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('posted_at'), isUtc: true),
    dueDate: DateTime.fromMillisecondsSinceEpoch(row.read<int>('due_at'), isUtc: true),
    effectiveDate: row.readNullable<int>('effective_at') == null ? null
      : DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('effective_at'), isUtc: true),
    isEffective: row.readNullable<int>('effective_at') != null &&
      row.read<int>('effective_at') <
        _dayMillis(DateTime.now().add(const Duration(days: 1))),
  );
}
