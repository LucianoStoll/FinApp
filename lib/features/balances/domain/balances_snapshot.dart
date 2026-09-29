class AccountBalance {
  const AccountBalance({required this.accountId, required this.currencyCode,
    required this.currentMinor, required this.projectedMinor});

  final String accountId;
  final String currencyCode;
  final int currentMinor;
  final int projectedMinor;
}

class CurrencyBalance {
  const CurrencyBalance({required this.currencyCode,
    required this.currentMinor, required this.projectedMinor});

  final String currencyCode;
  final int currentMinor;
  final int projectedMinor;
}

class BalancesSnapshot {
  const BalancesSnapshot({required this.accounts, required this.consolidated});

  final List<AccountBalance> accounts;
  /// Totais separados por moeda; nunca somar valores de moedas distintas.
  final List<CurrencyBalance> consolidated;
}
