class DashboardSummary {
  const DashboardSummary({
    required this.currentBalanceInMinorUnits,
    required this.projectedBalanceInMinorUnits,
  });

  final int currentBalanceInMinorUnits;
  final int projectedBalanceInMinorUnits;
}
