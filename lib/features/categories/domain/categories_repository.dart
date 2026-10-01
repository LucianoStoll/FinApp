import 'category.dart';

abstract interface class CategoriesRepository {
  Future<List<FinanceCategory>> list();
  Future<FinanceCategory> create(CategoryDraft draft);
  Future<FinanceCategory> update(String id, CategoryDraft draft);
  Future<FinanceCategory> setArchived(String id, {required bool archived});
}
