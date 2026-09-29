import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/categories_repository.dart';
import '../domain/category.dart';

class CategoriesState {
  const CategoriesState(
      {this.categories = const [], this.loading = false, this.error});

  final List<FinanceCategory> categories;
  final bool loading;
  final String? error;
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState()) {
    load();
  }

  final CategoriesRepository _repository;

  Future<void> load() async {
    emit(CategoriesState(categories: state.categories, loading: true));
    try {
      final categories = await _repository.list();
      if (!isClosed) emit(CategoriesState(categories: categories));
    } catch (_) {
      if (!isClosed) {
        emit(CategoriesState(
            categories: state.categories,
            error: 'Não foi possível carregar as categorias.'));
      }
    }
  }

  Future<void> save(CategoryDraft draft, {String? id}) async {
    if (id == null) {
      await _repository.create(draft);
    } else {
      await _repository.update(id, draft);
    }
    if (!isClosed) await load();
  }

  Future<void> setArchived(FinanceCategory category) async {
    await _repository.setArchived(category.id, archived: !category.isArchived);
    if (!isClosed) await load();
  }
}
