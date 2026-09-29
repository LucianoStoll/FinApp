import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/routing/somia_shell.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/accounts_repository.dart';
import '../../accounts/domain/money_minor.dart';
import '../../categories/domain/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../domain/financial_transaction.dart';
import '../domain/transactions_repository.dart';
import 'transactions_cubit.dart';

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, this.initialCreateType});
  final String? initialCreateType;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TransactionsCubit(getIt<TransactionsRepository>(),
          getIt<AccountsRepository>(), getIt<CategoriesRepository>()),
        child: _TransactionsView(initialCreateType: initialCreateType),
      );
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView({this.initialCreateType});
  final String? initialCreateType;

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  bool _openedInitial = false;
  TransactionType? _type;
  String? _accountId;
  String? _categoryId;
  String? _subcategoryId;
  TransactionStatus _status = TransactionStatus.all;
  DateTimeRange? _range;

  void _apply() => context.read<TransactionsCubit>().load(TransactionFilter(
        type: _type, accountId: _accountId,
        categoryId: _subcategoryId ?? _categoryId,
        status: _status, from: _range?.start, to: _range?.end,
      ));

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      initialDateRange: _range ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked != null && mounted) {
      setState(() => _range = picked);
      _apply();
    }
  }

  Future<void> _edit([FinancialTransaction? item]) async {
    final cubit = context.read<TransactionsCubit>();
    final state = cubit.state;
    final draft = await showDialog<TransactionDraft>(
      context: context,
      builder: (_) => _TransactionDialog(item: item,
        initialType: widget.initialCreateType == 'income'
          ? TransactionType.income : TransactionType.expense,
        accounts: state.accounts, categories: state.categories),
    );
    if (!mounted) return;
    if (draft == null) {
      if (item == null && widget.initialCreateType != null) context.go('/transactions');
      return;
    }
    try {
      await cubit.save(draft, id: item?.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
    if (mounted && item == null && widget.initialCreateType != null) {
      context.go('/transactions');
    }
  }

  Future<void> _delete(FinancialTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('“${item.description}” sairá da lista e dos saldos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<TransactionsCubit>().delete(item.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    final message = error is FormatException ? error.message
        : error is StateError ? error.message
        : 'Não foi possível salvar o lançamento.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Lançamentos'),
          leading: IconButton(
            tooltip: 'Voltar', icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        floatingActionButton: const SomiaQuickActions(),
        body: BlocConsumer<TransactionsCubit, TransactionsState>(
          listener: (context, state) {
            if (!_openedInitial && !state.loading && state.error == null &&
                (widget.initialCreateType == 'income' ||
                 widget.initialCreateType == 'expense')) {
              _openedInitial = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _edit();
              });
            }
          },
          builder: (context, state) {
            if (state.loading && state.accounts.isEmpty && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: TextButton(
                onPressed: context.read<TransactionsCubit>().load,
                child: Text('${state.error} Tentar novamente'),
              ));
            }
            return Column(children: [
              _filters(state),
              Expanded(child: state.items.isEmpty
                  ? const Center(child: Text('Nenhum lançamento para estes filtros.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) => _itemTile(state.items[index]),
                    )),
            ]);
          },
        ),
      );

  Widget _filters(TransactionsState state) => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(label: const Text('Todos'), selected: _type == null,
              onSelected: (_) { setState(() { _type = null; _categoryId = null; _subcategoryId = null; }); _apply(); }),
            for (final type in TransactionType.values)
              ChoiceChip(label: Text(type.label), selected: _type == type,
                onSelected: (_) { setState(() { _type = type; _categoryId = null; _subcategoryId = null; }); _apply(); }),
            DropdownButton<String>(
              value: _accountId ?? '', hint: const Text('Conta'),
              items: [const DropdownMenuItem(value: '', child: Text('Todas as contas')),
                for (final account in state.accounts)
                  DropdownMenuItem(value: account.id, child: Text(account.name))],
              onChanged: (id) { setState(() => _accountId = id == '' ? null : id); _apply(); },
            ),
            DropdownButton<String>(
              value: _categoryId ?? '', hint: const Text('Categoria'),
              items: [const DropdownMenuItem(value: '', child: Text('Todas as categorias')),
                for (final category in state.categories.where((c) =>
                    c.parentId == null &&
                    (_type == null || c.type.name == _type!.name)))
                  DropdownMenuItem(value: category.id, child: Text(category.name))],
              onChanged: (id) {
                setState(() { _categoryId = id == '' ? null : id; _subcategoryId = null; });
                _apply();
              },
            ),
            DropdownButton<String>(
              value: _subcategoryId ?? '', hint: const Text('Subcategoria'),
              items: [const DropdownMenuItem(value: '', child: Text('Todas as subcategorias')),
                for (final category in state.categories.where((c) =>
                    c.parentId == _categoryId && _categoryId != null))
                  DropdownMenuItem(value: category.id, child: Text(category.name))],
              onChanged: _categoryId == null ? null : (id) {
                setState(() => _subcategoryId = id == '' ? null : id);
                _apply();
              },
            ),
            DropdownButton<TransactionStatus>(
              value: _status,
              items: const [
                DropdownMenuItem(value: TransactionStatus.all, child: Text('Todos os estados')),
                DropdownMenuItem(value: TransactionStatus.effective, child: Text('Efetivados')),
                DropdownMenuItem(value: TransactionStatus.pending, child: Text('Pendentes')),
              ],
              onChanged: (status) {
                if (status != null) { setState(() => _status = status); _apply(); }
              },
            ),
            OutlinedButton.icon(
              onPressed: _pickRange, icon: const Icon(Icons.date_range),
              label: Text(_range == null ? 'Período'
                  : '${_dateLabel(_range!.start)} – ${_dateLabel(_range!.end)}'),
            ),
            if (_range != null) IconButton(
              tooltip: 'Limpar período', icon: const Icon(Icons.clear),
              onPressed: () { setState(() => _range = null); _apply(); },
            ),
          ],
        ),
      );

  Widget _itemTile(FinancialTransaction item) => Card(
        child: ListTile(
          leading: Icon(item.type == TransactionType.income
              ? Icons.arrow_downward : Icons.arrow_upward),
          title: Text(item.description),
          subtitle: Text('${_dateLabel(item.date)} · ${item.accountName}'
              '${item.categoryName == null ? '' : ' · ${item.categoryName}'}'
              '${item.isEffective ? '' : ' · Pendente'}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${item.type == TransactionType.income ? '+' : '-'}'
              '${MoneyMinor.display(item.amountMinor, item.currencyCode)}'),
            PopupMenuButton<String>(
              tooltip: 'Ações do lançamento',
              onSelected: (action) => action == 'edit' ? _edit(item) : _delete(item),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ]),
          onTap: () => _edit(item),
        ),
      );
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.accounts, required this.categories,
    this.item, this.initialType = TransactionType.expense});
  final FinancialTransaction? item;
  final TransactionType initialType;
  final List<Account> accounts;
  final List<FinanceCategory> categories;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late TransactionType _type;
  late DateTime _date;
  late bool _isEffective;
  String? _accountId;
  String? _categoryId;
  String? _subcategoryId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _description = TextEditingController(text: item?.description ?? '');
    _amount = TextEditingController(text: MoneyMinor.plain(item?.amountMinor ?? 0));
    _type = item?.type ?? widget.initialType;
    _date = item?.date ?? DateTime.now();
    _isEffective = item?.isEffective ?? true;
    _accountId = item?.accountId ?? _availableAccounts.firstOrNull?.id;
    final selected = widget.categories.where((category) =>
        category.id == item?.categoryId).firstOrNull;
    _categoryId = selected?.parentId ?? selected?.id;
    _subcategoryId = selected?.parentId == null ? null : selected?.id;
  }

  List<Account> get _availableAccounts => widget.accounts.where((account) =>
      !account.isArchived || account.id == widget.item?.accountId).toList();

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context,
      initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, TransactionDraft(
      description: _description.text.trim(), type: _type,
      amountMinor: MoneyMinor.parse(_amount.text), date: _date,
      isEffective: _isEffective, accountId: _accountId!,
      categoryId: _subcategoryId ?? _categoryId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final roots = widget.categories.where((category) =>
        category.parentId == null && category.type.name == _type.name &&
        (!category.isArchived || category.id == _categoryId)).toList();
    final children = widget.categories.where((category) =>
        category.parentId == _categoryId && _categoryId != null &&
        (!category.isArchived || category.id == _subcategoryId)).toList();
    return AlertDialog(
      title: Text(widget.item == null ? 'Novo lançamento' : 'Editar lançamento'),
      content: SizedBox(width: 440,
        child: Form(key: _formKey, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<TransactionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: TransactionType.values.map((type) => DropdownMenuItem(
                value: type, child: Text(type.label))).toList(),
              onChanged: (type) {
                if (type != null) setState(() { _type = type; _categoryId = null; _subcategoryId = null; });
              },
            ),
            TextFormField(controller: _description,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe a descrição.' : null),
            TextFormField(controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (value) {
                try {
                  return MoneyMinor.parse(value ?? '') > 0
                      ? null : 'O valor deve ser maior que zero.';
                } on FormatException catch (error) { return error.message; }
              }),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Conta'),
              items: _availableAccounts.map((account) => DropdownMenuItem(
                value: account.id,
                child: Text('${account.name}${account.isArchived ? ' (arquivada)' : ''}'),
              )).toList(),
              validator: (value) => value == null ? 'Cadastre uma conta ativa.' : null,
              onChanged: (id) => setState(() => _accountId = id),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('category-${_type.name}'),
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [const DropdownMenuItem(value: '', child: Text('Sem categoria')),
                for (final category in roots)
                  DropdownMenuItem(value: category.id,
                    child: Text('${category.name}'
                        '${category.isArchived ? ' (arquivada)' : ''}'))],
              onChanged: (id) => setState(() {
                _categoryId = id == null || id.isEmpty ? null : id;
                _subcategoryId = null;
              }),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('subcategory-${_type.name}-$_categoryId'),
              initialValue: _subcategoryId,
              decoration: const InputDecoration(labelText: 'Subcategoria'),
              items: [const DropdownMenuItem(value: '', child: Text('Nenhuma')),
                for (final category in children)
                  DropdownMenuItem(value: category.id,
                    child: Text('${category.name}'
                        '${category.isArchived ? ' (arquivada)' : ''}'))],
              onChanged: _categoryId == null ? null : (id) => setState(() =>
                  _subcategoryId = id == null || id.isEmpty ? null : id),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'), subtitle: Text(_dateLabel(_date)),
              trailing: const Icon(Icons.calendar_today), onTap: _pickDate,
            ),
            SwitchListTile(
              title: const Text('Efetivada'),
              subtitle: const Text('Pendentes não alteram o saldo atual'),
              value: _isEffective,
              onChanged: (value) => setState(() => _isEffective = value),
            ),
          ]),
        )),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
