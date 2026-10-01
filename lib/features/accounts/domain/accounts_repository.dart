import 'account.dart';

abstract interface class AccountsRepository {
  Future<List<Account>> list({DateTime? asOf, DateTime? through});
  Future<Account> create(AccountDraft draft);
  Future<Account> update(String id, AccountDraft draft);
  Future<Account> setArchived(String id, {required bool archived});
}
