import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/dashboard_repository.dart';
import '../domain/entities/dashboard_summary.dart';

class DashboardState {
  const DashboardState({required this.month, this.summary, this.loading = false,
    this.error});

  final DateTime month;
  final DashboardSummary? summary;
  final bool loading;
  final String? error;
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(DashboardState(
    month: DateTime(DateTime.now().year, DateTime.now().month))) {
    load();
  }

  final DashboardRepository _repository;

  Future<void> load([DateTime? month]) async {
    final selected = month ?? state.month;
    final previousSummary = selected.year == state.month.year &&
        selected.month == state.month.month ? state.summary : null;
    emit(DashboardState(month: selected, summary: previousSummary, loading: true));
    try {
      final summary = await _repository.load(selected);
      if (!isClosed) emit(DashboardState(month: selected, summary: summary));
    } catch (_) {
      if (!isClosed) {
        emit(DashboardState(month: selected, summary: previousSummary,
          error: 'Não foi possível carregar o resumo.'));
      }
    }
  }

  void moveMonth(int delta) => load(DateTime(state.month.year,
    state.month.month + delta));
}
