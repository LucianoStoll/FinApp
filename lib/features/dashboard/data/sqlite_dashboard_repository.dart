import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../balances/data/sqlite_balances_repository.dart';
import '../domain/dashboard_repository.dart';
import '../domain/entities/dashboard_summary.dart';

class SqliteDashboardRepository implements DashboardRepository {
  const SqliteDashboardRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DashboardSummary> load(DateTime month) => _db.transaction(() async {
    final start = DateTime.utc(month.year, month.month).millisecondsSinceEpoch;
    final end = DateTime.utc(month.year, month.month + 1).millisecondsSinceEpoch;
    final balances = await SqliteBalancesRepository(_db).calculate();
    final totals = <String, (int, int)>{};
    final period = await _db.customSelect('''
      SELECT a.currency_code, t.type, SUM(t.actual_amount_minor) AS amount_minor
      FROM transactions t JOIN accounts a ON a.id = t.account_id
      WHERE t.deleted_at IS NULL AND t.effective_at IS NOT NULL
        AND t.actual_amount_minor IS NOT NULL AND t.ignore_analytics = 0
        AND a.deleted_at IS NULL AND a.include_in_analytics = 1
        AND t.competence_at >= ? AND t.competence_at < ?
      GROUP BY a.currency_code, t.type
    ''', variables: [Variable.withInt(start), Variable.withInt(end)]).get();
    for (final row in period) {
      final currency = row.read<String>('currency_code');
      final previous = totals[currency] ?? (0, 0);
      final amount = row.read<int>('amount_minor');
      totals[currency] = row.read<String>('type') == 'income'
          ? (previous.$1 + amount, previous.$2)
          : (previous.$1, previous.$2 + amount);
    }
    // Mesmo que não existam contas ativas na moeda, os totais do período
    // permanecem disponíveis enquanto a conta histórica não foi removida.
    final currencies = <String>{
      ...balances.consolidated.map((value) => value.currencyCode),
      ...totals.keys,
    }.toList()..sort();
    final byCurrency = {
      for (final value in balances.consolidated) value.currencyCode: value,
    };
    final summaries = [
      for (final currency in currencies)
        DashboardCurrencySummary(currencyCode: currency,
          currentBalanceMinor: byCurrency[currency]?.currentMinor ?? 0,
          projectedBalanceMinor: byCurrency[currency]?.projectedMinor ?? 0,
          incomeMinor: totals[currency]?.$1 ?? 0,
          expenseMinor: totals[currency]?.$2 ?? 0),
    ];
    final rows = await _db.customSelect('''
      SELECT id, type, description, account_label, currency_code,
        amount_minor, event_at, effective_at, created_at FROM (
        SELECT t.id, t.type, t.description, a.name AS account_label,
          a.currency_code,
          COALESCE(t.actual_amount_minor, t.planned_amount_minor) AS amount_minor,
          t.competence_at AS event_at, t.effective_at, t.created_at
        FROM transactions t JOIN accounts a ON a.id = t.account_id
        WHERE t.deleted_at IS NULL AND a.deleted_at IS NULL
        UNION ALL
        SELECT f.id, 'transfer' AS type, 'Transferência' AS description,
          source.name || ' → ' || destination.name AS account_label,
          source.currency_code, f.amount_minor, f.planned_at AS event_at,
          f.effective_at, f.created_at
        FROM transfers f
        JOIN accounts source ON source.id = f.source_account_id
        JOIN accounts destination ON destination.id = f.destination_account_id
        WHERE f.deleted_at IS NULL
          AND source.deleted_at IS NULL AND destination.deleted_at IS NULL
      ) ORDER BY created_at DESC, id DESC LIMIT 5
    ''').get();
    final recent = rows.map((row) => DashboardActivity(
      id: row.read<String>('id'),
      type: DashboardActivityType.values.byName(row.read<String>('type')),
      description: row.read<String>('description'),
      accountLabel: row.read<String>('account_label'),
      currencyCode: row.read<String>('currency_code'),
      amountMinor: row.read<int>('amount_minor'),
      date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('event_at'), isUtc: true),
      isEffective: row.readNullable<int>('effective_at') != null,
    )).toList();
    return DashboardSummary(month: DateTime(month.year, month.month),
      currencies: summaries, recent: recent);
  });
}
