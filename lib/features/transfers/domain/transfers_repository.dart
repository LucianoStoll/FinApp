import 'transfer.dart';

abstract interface class TransfersRepository {
  Future<List<Transfer>> list({String? accountId});
  Future<Transfer> create(TransferDraft draft);
  Future<Transfer> update(String id, TransferDraft draft);
  Future<void> delete(String id);
}
