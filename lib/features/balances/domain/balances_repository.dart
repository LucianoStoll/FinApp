import 'balances_snapshot.dart';

abstract interface class BalancesRepository {
  /// [asOf] limita os movimentos efetivados ao fim do dia. Lançamentos
  /// efetivados depois dessa data são tratados como previstos na projeção.
  /// [through] limita a data planejada dos movimentos projetados.
  Future<BalancesSnapshot> calculate({DateTime? asOf, DateTime? through});
}
