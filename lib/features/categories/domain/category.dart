enum CategoryType {
  expense('Despesa'),
  income('Receita');

  const CategoryType(this.label);
  final String label;
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.parentId,
    required this.isArchived,
    required this.iconKey,
    required this.colorArgb,
  });

  final String id;
  final String name;
  final CategoryType type;
  final String? parentId;
  final bool isArchived;
  final String? iconKey;
  final int? colorArgb;

  bool get isSubcategory => parentId != null;
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.type,
    this.parentId,
    this.iconKey,
    this.colorArgb,
  });

  final String name;
  final CategoryType type;
  final String? parentId;
  final String? iconKey;
  final int? colorArgb;
}
