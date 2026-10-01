import 'transfer.dart';

abstract interface class TransfersRepository {
  Future<List<Transfer>> list({String? accountId});
  Future<Transfer> create(TransferDraft draft);
  Future<Transfer> update(String id, TransferDraft draft);
  Future<void> setEffective(String id,
      {required bool effective, DateTime? effectiveDate});

  /// Altera apenas a efetivação se a data ainda corresponder à ação original.
  Future<void> changeEffectiveDate(String id,
      {required DateTime expectedDate, DateTime? effectiveDate});
  Future<void> delete(String id);
}
