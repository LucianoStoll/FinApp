enum TransactionType {
  expense('Despesa'),
  income('Receita');

  const TransactionType(this.label);
  final String label;
}

enum TransactionStatus { all, effective, pending }

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.description,
    required this.type,
    required this.amountMinor,
    required this.date,
    required this.isEffective,
    required this.accountId,
    required this.accountName,
    required this.categoryId,
    required this.categoryName,
    required this.currencyCode,
  });

  final String id;
  final String description;
  final TransactionType type;
  final int amountMinor;
  final DateTime date;
  final bool isEffective;
  final String accountId;
  final String accountName;
  final String? categoryId;
  final String? categoryName;
  final String currencyCode;
}

class TransactionDraft {
  const TransactionDraft({
    required this.description,
    required this.type,
    required this.amountMinor,
    required this.date,
    required this.isEffective,
    required this.accountId,
    this.categoryId,
  });

  final String description;
  final TransactionType type;
  final int amountMinor;
  final DateTime date;
  final bool isEffective;
  final String accountId;
  final String? categoryId;
}

class TransactionFilter {
  const TransactionFilter({this.type, this.accountId, this.categoryId,
    this.status = TransactionStatus.all, this.from, this.to});

  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final TransactionStatus status;
  final DateTime? from;
  final DateTime? to;
}
