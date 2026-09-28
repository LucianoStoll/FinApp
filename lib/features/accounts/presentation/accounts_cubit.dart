import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/account.dart';
import '../domain/accounts_repository.dart';

class AccountsState {
  const AccountsState({this.accounts = const [], this.loading = false, this.error});

  final List<Account> accounts;
  final bool loading;
  final String? error;
}

class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository) : super(const AccountsState()) {
    load();
  }

  final AccountsRepository _repository;

  Future<void> load() async {
    emit(AccountsState(accounts: state.accounts, loading: true));
    try {
      emit(AccountsState(accounts: await _repository.list()));
    } catch (_) {
      emit(AccountsState(accounts: state.accounts, error: 'Não foi possível carregar as contas.'));
    }
  }

  Future<void> save(AccountDraft draft, {String? id}) async {
    if (id == null) {
      await _repository.create(draft);
    } else {
      await _repository.update(id, draft);
    }
    await load();
  }

  Future<void> setArchived(Account account) async {
    await _repository.setArchived(account.id, archived: !account.isArchived);
    await load();
  }
}
