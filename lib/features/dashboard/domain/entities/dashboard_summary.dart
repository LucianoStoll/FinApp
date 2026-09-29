class DashboardCurrencySummary {
  const DashboardCurrencySummary({required this.currencyCode,
    required this.currentBalanceMinor, required this.projectedBalanceMinor,
    required this.incomeMinor, required this.expenseMinor});

  final String currencyCode;
  final int currentBalanceMinor;
  final int projectedBalanceMinor;
  final int incomeMinor;
  final int expenseMinor;
}

enum DashboardActivityType { income, expense, transfer }

class DashboardActivity {
  const DashboardActivity({required this.id, required this.type,
    required this.description, required this.accountLabel,
    required this.currencyCode, required this.amountMinor,
    required this.date, required this.isEffective});

  final String id;
  final DashboardActivityType type;
  final String description;
  final String accountLabel;
  final String currencyCode;
  final int amountMinor;
  final DateTime date;
  final bool isEffective;
}

class DashboardSummary {
  const DashboardSummary({required this.month, required this.currencies,
    required this.recent});

  final DateTime month;
  final List<DashboardCurrencySummary> currencies;
  final List<DashboardActivity> recent;

  bool get isEmpty => currencies.isEmpty && recent.isEmpty;
}
