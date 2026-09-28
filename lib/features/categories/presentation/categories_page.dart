import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../domain/categories_repository.dart';
import '../domain/category.dart';
import 'categories_cubit.dart';

const _icons = <String, IconData>{
  'shopping': Icons.shopping_bag_outlined,
  'food': Icons.restaurant_outlined,
  'home': Icons.home_outlined,
  'transport': Icons.directions_car_outlined,
  'work': Icons.work_outline,
  'other': Icons.label_outline,
};

const _colors = <int, String>{
  0xff1976d2: 'Azul',
  0xff388e3c: 'Verde',
  0xffef6c00: 'Laranja',
  0xff7b1fa2: 'Roxo',
  0xffc62828: 'Vermelho',
  0xff455a64: 'Cinza',
};

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CategoriesCubit(getIt<CategoriesRepository>()),
        child: const _CategoriesView(),
      );
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  CategoryType _filter = CategoryType.expense;

  Future<void> _edit([FinanceCategory? category]) async {
    final categories = context.read<CategoriesCubit>().state.categories;
    final draft = await showDialog<CategoryDraft>(
      context: context,
      builder: (_) => _CategoryDialog(category: category, categories: categories,
          defaultType: _filter),
    );
    if (draft == null || !mounted) return;
    try {
      await context.read<CategoriesCubit>().save(draft, id: category?.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _archive(FinanceCategory category) async {
    try {
      await context.read<CategoriesCubit>().setArchived(category);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    final message = error is FormatException ? error.message
        : error is StateError ? error.message
        : 'Não foi possível salvar a categoria.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Categorias'),
          leading: IconButton(
            tooltip: 'Voltar', icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const Text('Nova categoria'),
        ),
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state.loading && state.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: TextButton(
                onPressed: context.read<CategoriesCubit>().load,
                child: Text('${state.error} Tentar novamente'),
              ));
            }
            final roots = state.categories.where(
              (category) => category.type == _filter && !category.isSubcategory,
            ).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<CategoryType>(
                    segments: CategoryType.values.map((type) => ButtonSegment(
                      value: type, label: Text(type.label),
                    )).toList(),
                    selected: {_filter},
                    onSelectionChanged: (selection) =>
                        setState(() => _filter = selection.first),
                  ),
                ),
                Expanded(
                  child: roots.isEmpty
                      ? const Center(child: Text('Nenhuma categoria cadastrada.'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                          children: [
                            for (final root in roots) ...[
                              _categoryTile(root),
                              for (final child in state.categories.where(
                                  (category) => category.parentId == root.id))
                                Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: _categoryTile(child),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      );

  Widget _categoryTile(FinanceCategory category) => Card(
        child: ListTile(
          leading: Icon(_icons[category.iconKey] ?? Icons.label_outline,
              color: category.colorArgb == null ? null : Color(category.colorArgb!)),
          title: Text(category.name),
          subtitle: Text(category.isArchived
              ? 'Arquivada · histórico preservado'
              : category.isSubcategory ? 'Subcategoria' : 'Categoria principal'),
          onTap: () => _edit(category),
          trailing: PopupMenuButton<String>(
            tooltip: 'Ações da categoria',
            onSelected: (action) => action == 'edit'
                ? _edit(category) : _archive(category),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'archive',
                child: Text(category.isArchived ? 'Reativar' : 'Arquivar')),
            ],
          ),
        ),
      );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.categories, required this.defaultType,
    this.category});
  final FinanceCategory? category;
  final List<FinanceCategory> categories;
  final CategoryType defaultType;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late CategoryType _type;
  String? _parentId;
  String _iconKey = 'other';
  int _colorArgb = 0xff1976d2;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _type = widget.category?.type ?? widget.defaultType;
    _parentId = widget.category?.parentId;
    _iconKey = widget.category?.iconKey ?? 'other';
    _colorArgb = widget.category?.colorArgb ?? 0xff1976d2;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, CategoryDraft(
      name: _name.text.trim(), type: _type, parentId: _parentId,
      iconKey: _iconKey, colorArgb: _colorArgb,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final parents = widget.categories.where((category) =>
        category.type == _type && !category.isSubcategory &&
        (!category.isArchived || category.id == _parentId) &&
        category.id != widget.category?.id).toList();
    return AlertDialog(
      title: Text(widget.category == null ? 'Nova categoria' : 'Editar categoria'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome.' : null,
              ),
              DropdownButtonFormField<CategoryType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: CategoryType.values.map((type) => DropdownMenuItem(
                  value: type, child: Text(type.label),
                )).toList(),
                onChanged: (type) {
                  if (type != null) setState(() { _type = type; _parentId = null; });
                },
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _parentId,
                decoration: const InputDecoration(labelText: 'Categoria principal'),
                hint: const Text('Nenhuma (categoria principal)'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Nenhuma')),
                  for (final parent in parents)
                    DropdownMenuItem(value: parent.id, child: Text(parent.name)),
                ],
                onChanged: (id) => setState(() =>
                    _parentId = id == null || id.isEmpty ? null : id),
              ),
              DropdownButtonFormField<String>(
                initialValue: _iconKey,
                decoration: const InputDecoration(labelText: 'Ícone'),
                items: _icons.entries.map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(entry.value), const SizedBox(width: 8), Text(entry.key),
                  ]),
                )).toList(),
                onChanged: (key) {
                  if (key != null) setState(() => _iconKey = key);
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: _colorArgb,
                decoration: const InputDecoration(labelText: 'Cor'),
                items: _colors.entries.map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, color: Color(entry.key)),
                    const SizedBox(width: 8), Text(entry.value),
                  ]),
                )).toList(),
                onChanged: (color) {
                  if (color != null) setState(() => _colorArgb = color);
                },
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
