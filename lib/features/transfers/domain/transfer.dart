class Transfer {
  const Transfer({
    required this.id,
    required this.sourceAccountId,
    required this.sourceAccountName,
    required this.destinationAccountId,
    required this.destinationAccountName,
    required this.currencyCode,
    required this.amountMinor,
    required this.date,
    required this.isEffective,
  });

  final String id;
  final String sourceAccountId;
  final String sourceAccountName;
  final String destinationAccountId;
  final String destinationAccountName;
  final String currencyCode;
  final int amountMinor;
  final DateTime date;
  final bool isEffective;
}

class TransferDraft {
  const TransferDraft({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinor,
    required this.date,
    required this.isEffective,
  });

  final String sourceAccountId;
  final String destinationAccountId;
  final int amountMinor;
  final DateTime date;
  final bool isEffective;
}
