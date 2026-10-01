import 'financial_transaction.dart';

abstract interface class TransactionsRepository {
  Future<List<FinancialTransaction>> list([TransactionFilter filter]);
  Future<FinancialTransaction> create(TransactionDraft draft);
  Future<FinancialTransaction> update(String id, TransactionDraft draft);
  Future<void> setEffective(String id,
      {required bool effective, DateTime? effectiveDate});

  /// Altera apenas a efetivação se a data ainda corresponder à ação original.
  Future<void> changeEffectiveDate(String id,
      {required DateTime expectedDate, DateTime? effectiveDate});
  Future<void> delete(String id);
}
