import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/financial_transaction.dart';

/// Uma fotografia do histórico ao abrir o formulário, sem dados de faturas
/// agrupadas ou ajustes. A primeira classificação válida vence.
class CategoryHistoryRepository {
  const CategoryHistoryRepository(this.db);
  final AppDatabase db;

  static String normalize(String description) =>
      description.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Map<String, String>> load(TransactionType type) async {
    final rows = await db.customSelect('''
      SELECT h.description,c.id AS category_id FROM (
        SELECT id,description,type,category_id,updated_at,created_at
        FROM transactions WHERE deleted_at IS NULL AND category_id IS NOT NULL
        UNION ALL
        SELECT id,description,'expense' AS type,category_id,updated_at,created_at
        FROM card_entries WHERE deleted_at IS NULL AND kind='purchase' AND category_id IS NOT NULL
      ) h
      JOIN categories c ON c.id=h.category_id
      LEFT JOIN categories p ON p.id=c.parent_id
      WHERE h.type=? AND c.type=h.type AND c.deleted_at IS NULL AND c.is_archived=0
        AND (c.parent_id IS NULL OR
          (p.id IS NOT NULL AND p.parent_id IS NULL AND p.type=h.type AND p.deleted_at IS NULL AND p.is_archived=0))
      ORDER BY h.updated_at DESC,h.created_at DESC,h.id DESC
      ''', variables: [Variable.withString(type.name)]).get();
    final result = <String, String>{};
    for (final row in rows) {
      final text = normalize(row.read<String>('description'));
      if (text.isNotEmpty) {
        result.putIfAbsent(text, () => row.read<String>('category_id'));
      }
    }
    return result;
  }
}
