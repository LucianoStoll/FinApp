import 'package:flutter_bloc/flutter_bloc.dart';

import '../../accounts/domain/account.dart';
import '../../accounts/domain/accounts_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfers_repository.dart';

class TransfersState {
  const TransfersState(
      {this.items = const [],
      this.accounts = const [],
      this.loading = false,
      this.error});

  final List<Transfer> items;
  final List<Account> accounts;
  final bool loading;
  final String? error;
}

class TransfersCubit extends Cubit<TransfersState> {
  TransfersCubit(this._transfers, this._accounts)
      : super(const TransfersState()) {
    load();
  }

  final TransfersRepository _transfers;
  final AccountsRepository _accounts;

  Future<void> load() async {
    emit(TransfersState(
        items: state.items, accounts: state.accounts, loading: true));
    try {
      final items = await _transfers.list();
      final accounts = await _accounts.list();
      if (!isClosed) emit(TransfersState(items: items, accounts: accounts));
    } catch (_) {
      if (!isClosed) {
        emit(TransfersState(
            items: state.items,
            accounts: state.accounts,
            error: 'Não foi possível carregar as transferências.'));
      }
    }
  }

  Future<void> save(TransferDraft draft, {String? id}) async {
    if (id == null) {
      await _transfers.create(draft);
    } else {
      await _transfers.update(id, draft);
    }
    if (!isClosed) await load();
  }

  Future<void> delete(String id) async {
    await _transfers.delete(id);
    if (!isClosed) await load();
  }

  Future<void> setEffective(String id,
      {required bool effective, DateTime? effectiveDate}) async {
    await _transfers.setEffective(id,
        effective: effective, effectiveDate: effectiveDate);
    if (!isClosed) await load();
  }
}
