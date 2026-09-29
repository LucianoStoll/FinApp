import 'financial_transaction.dart';

abstract interface class TransactionsRepository {
  Future<List<FinancialTransaction>> list([TransactionFilter filter]);
  Future<FinancialTransaction> create(TransactionDraft draft);
  Future<FinancialTransaction> update(String id, TransactionDraft draft);
  Future<void> delete(String id);
}
