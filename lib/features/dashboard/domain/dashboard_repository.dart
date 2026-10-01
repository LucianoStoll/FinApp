import 'entities/dashboard_summary.dart';

abstract interface class DashboardRepository {
  /// Resumo de um mês de competência; receitas e despesas contam apenas
  /// lançamentos efetivados e visíveis nas análises.
  Future<DashboardSummary> load(DateTime month);
}
