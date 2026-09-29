import 'balances_snapshot.dart';

abstract interface class BalancesRepository {
  /// Sem data limite, considera todas as pendências. Com data, inclui as
  /// pendências planejadas até o fim daquele dia.
  Future<BalancesSnapshot> calculate({DateTime? through});
}
