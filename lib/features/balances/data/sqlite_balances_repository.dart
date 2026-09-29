import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/balances_repository.dart';
import '../domain/balances_snapshot.dart';

/// Consulta compartilhada com a listagem de contas para manter a mesma
/// definição de saldo em toda a aplicação.
Future<List<QueryRow>> balanceRows(AppDatabase db, {DateTime? through}) {
  final end = through == null ? null : DateTime.utc(
    through.year, through.month, through.day + 1).millisecondsSinceEpoch;
  final txUntil = end == null ? '' : 'AND t.competence_at < ?';
  final transferUntil = end == null ? '' : 'AND f.planned_at < ?';
  final variables = <Variable>[
    if (end != null) Variable.withInt(end),
    if (end != null) Variable.withInt(end),
  ];
  return db.customSelect('''
    SELECT a.*,
      a.initial_balance_minor +
      COALESCE((SELECT SUM(CASE WHEN t.type = 'income'
                      THEN t.actual_amount_minor ELSE -t.actual_amount_minor END)
                FROM transactions t
                WHERE t.account_id = a.id AND t.effective_at IS NOT NULL
                  AND t.actual_amount_minor IS NOT NULL
                  AND t.ignore_balance = 0 AND t.deleted_at IS NULL), 0) +
      COALESCE((SELECT SUM(CASE WHEN f.destination_account_id = a.id
                      THEN f.amount_minor ELSE -f.amount_minor END)
                FROM transfers f
                WHERE (f.source_account_id = a.id OR f.destination_account_id = a.id)
                  AND f.effective_at IS NOT NULL AND f.deleted_at IS NULL), 0)
      AS current_balance_minor,
      COALESCE((SELECT SUM(CASE WHEN t.type = 'income'
                      THEN t.planned_amount_minor ELSE -t.planned_amount_minor END)
                FROM transactions t
                WHERE t.account_id = a.id AND t.effective_at IS NULL
                  AND t.ignore_balance = 0 AND t.deleted_at IS NULL
                  $txUntil), 0) +
      COALESCE((SELECT SUM(CASE WHEN f.destination_account_id = a.id
                      THEN f.amount_minor ELSE -f.amount_minor END)
                FROM transfers f
                WHERE (f.source_account_id = a.id OR f.destination_account_id = a.id)
                  AND f.effective_at IS NULL AND f.deleted_at IS NULL
                  $transferUntil), 0)
      AS pending_balance_minor
    FROM accounts a
    WHERE a.deleted_at IS NULL
    ORDER BY a.is_archived, lower(a.name), a.id
  ''', variables: variables).get();
}

class SqliteBalancesRepository implements BalancesRepository {
  const SqliteBalancesRepository(this._db);

  final AppDatabase _db;

  @override
  Future<BalancesSnapshot> calculate({DateTime? through}) async {
    final rows = await balanceRows(_db, through: through);
    final accounts = <AccountBalance>[];
    final totals = <String, (int, int)>{};
    for (final row in rows) {
      final currency = row.read<String>('currency_code');
      final current = row.read<int>('current_balance_minor');
      final projected = current + row.read<int>('pending_balance_minor');
      accounts.add(AccountBalance(accountId: row.read<String>('id'),
        currencyCode: currency, currentMinor: current,
        projectedMinor: projected));
      final previous = totals[currency] ?? (0, 0);
      totals[currency] = (previous.$1 + current, previous.$2 + projected);
    }
    final consolidated = totals.entries.map((entry) => CurrencyBalance(
      currencyCode: entry.key, currentMinor: entry.value.$1,
      projectedMinor: entry.value.$2)).toList()
      ..sort((a, b) => a.currencyCode.compareTo(b.currencyCode));
    return BalancesSnapshot(accounts: accounts, consolidated: consolidated);
  }
}
