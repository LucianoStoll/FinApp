import 'package:flutter/material.dart';

import '../../../core/widgets/movement_form_frame.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../../core/widgets/movement_list_row.dart';
import '../../../core/widgets/effectuation_feedback.dart';
import '../../../core/widgets/monetary_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/filters/reference_month.dart';
import '../../../core/widgets/month_selector.dart';
import '../../../core/routing/somia_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/effectuation_date_dialog.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/accounts_repository.dart';
import '../../accounts/domain/money_minor.dart';
import '../../categories/domain/categories_repository.dart';
import '../../categories/domain/category.dart';
import '../domain/financial_transaction.dart';
import '../domain/transactions_repository.dart';
import 'transactions_cubit.dart';

String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key, this.initialCreateType, this.sectionType});
  final String? initialCreateType;
  final TransactionType? sectionType;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TransactionsCubit(getIt<TransactionsRepository>(),
            getIt<AccountsRepository>(), getIt<CategoriesRepository>(),
            sectionType: sectionType, month: referenceMonth.value),
        child: _TransactionsView(
            initialCreateType: initialCreateType, sectionType: sectionType),
      );
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView({this.initialCreateType, this.sectionType});
  final String? initialCreateType;
  final TransactionType? sectionType;

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  bool _openedInitial = false;
  final Set<String> _changingStatus = {};
  TransactionType? _type;
  String? _accountId;
  String? _categoryId;
  String? _subcategoryId;
  TransactionStatus _status = TransactionStatus.all;
  TransactionDateField _dateField = TransactionDateField.due;
  DateTimeRange? _range;
  bool _customPeriod = false;
  VoidCallback? _refreshFilters;
  DateTimeRange get _monthRange => DateTimeRange(
      start: referenceMonth.value,
      end: DateTime(
          referenceMonth.value.year, referenceMonth.value.month + 1, 0));

  void _monthChanged() {
    setState(() {
      _range = _monthRange;
      _customPeriod = false;
    });
    _apply();
  }

  @override
  void dispose() {
    referenceMonth.removeListener(_monthChanged);
    super.dispose();
  }

  Future<void> _openFilters(TransactionsState state) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheet) => StatefulBuilder(builder: (sheet, refresh) {
              _refreshFilters = () {
                if (sheet.mounted) refresh(() {});
              };
              return SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          const Expanded(
                              child: Text('Filtros',
                                  style: TextStyle(fontSize: 20))),
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  _type = widget.sectionType;
                                  _accountId = null;
                                  _categoryId = null;
                                  _subcategoryId = null;
                                  _status = TransactionStatus.all;
                                  _dateField = TransactionDateField.due;
                                  _range = _monthRange;
                                  _customPeriod = false;
                                });
                                _apply();
                              },
                              child: const Text('Limpar filtros')),
                          IconButton(
                              tooltip: 'Fechar filtros',
                              onPressed: () => Navigator.pop(sheet),
                              icon: const Icon(Icons.close)),
                        ]),
                        _filters(state),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                _range = null;
                                _customPeriod = true;
                              });
                              _apply();
                            },
                            child: const Text('Todos os meses')),
                      ])));
            }));
    _refreshFilters = null;
  }

  @override
  void initState() {
    super.initState();
    _type = widget.sectionType;
    _range = _monthRange;
    referenceMonth.addListener(_monthChanged);
  }

  String get _sectionPath => widget.sectionType == TransactionType.income
      ? '/income'
      : widget.sectionType == TransactionType.expense
          ? '/expenses'
          : '/transactions';

  void _apply() {
    _refreshFilters?.call();
    context.read<TransactionsCubit>().load(TransactionFilter(
          type: _type,
          accountId: _accountId,
          categoryId: _subcategoryId ?? _categoryId,
          status: _status,
          from: _range?.start,
          to: _range?.end,
          dateField: _dateField,
        ));
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked != null && mounted) {
      setState(() {
        _range = picked;
        _customPeriod = true;
      });
      _apply();
    }
  }

  Future<void> _edit([FinancialTransaction? item]) async {
    final cubit = context.read<TransactionsCubit>();
    final state = cubit.state;
    final draft = await showMovementForm<TransactionDraft>(
      context,
      (_) => TransactionForm(
          item: item,
          fixedType: widget.sectionType,
          initialType: (widget.sectionType == TransactionType.income ||
                  widget.initialCreateType == 'income')
              ? TransactionType.income
              : TransactionType.expense,
          accounts: state.accounts,
          categories: state.categories),
    );
    if (!mounted) return;
    if (draft == null) {
      if (item == null && widget.initialCreateType != null) {
        context.go(_sectionPath);
      }
      return;
    }
    try {
      await cubit.save(draft, id: item?.id);
    } catch (error) {
      if (mounted) _showError(error);
    }
    if (mounted && item == null && widget.initialCreateType != null) {
      context.go(_sectionPath);
    }
  }

  Future<void> _delete(FinancialTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('“${item.description}” sairá da lista e dos saldos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
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

  Future<void> _markPending(FinancialTransaction item) async {
    if (item.effectiveDate == null) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _changeDate(item.id, item.effectiveDate!);
  }

  Future<void> _editAmount(FinancialTransaction item) async {
    if (!mounted || _changingStatus.contains(item.id)) return;
    setState(() => _changingStatus.add(item.id));
    try {
      final amount = await showMonetaryCalculator(context,
          initialMinor: item.amountMinor,
          currencyCode: item.currencyCode,
          minimumMinor: 1);
      if (!mounted || amount == null || amount == item.amountMinor) return;
      await context.read<TransactionsCubit>().updateAmount(item.id,
          expectedAmountMinor: item.amountMinor, amountMinor: amount);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _changingStatus.remove(item.id));
    }
  }

  Future<void> _quickEffective(FinancialTransaction item) async {
    if (!mounted || item.isEffective || _changingStatus.contains(item.id)) {
      return;
    }
    setState(() => _changingStatus.add(item.id));
    final today = DateUtils.dateOnly(DateTime.now());
    try {
      await context
          .read<TransactionsCubit>()
          .setEffective(item.id, effective: true, effectiveDate: today);
      if (!mounted) return;
      showEffectuationFeedback(context,
          message: item.type == TransactionType.income
              ? 'Receita recebida hoje.'
              : 'Despesa paga hoje.',
          undo: () => _changeDate(item.id, today, restore: item.effectiveDate),
          adjustDate: () => _changeDate(item.id, today, pick: true));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _changingStatus.remove(item.id));
    }
  }

  Future<void> _changeDate(String id, DateTime expected,
      {DateTime? restore, bool pick = false}) async {
    if (!mounted || _changingStatus.contains(id)) return;
    setState(() => _changingStatus.add(id));
    try {
      final chosen = pick
          ? await showDatePicker(
              context: context,
              initialDate: expected,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100))
          : restore;
      if (!mounted || (pick && chosen == null)) return;
      await context.read<TransactionsCubit>().changeEffectiveDate(id,
          expectedDate: expected, effectiveDate: chosen);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _changingStatus.remove(id));
    }
  }

  void _showError(Object error) {
    final message = error is FormatException
        ? error.message
        : error is StateError
            ? error.message
            : 'Não foi possível salvar o lançamento.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.sectionType == TransactionType.income
              ? 'Receitas'
              : widget.sectionType == TransactionType.expense
                  ? 'Despesas'
                  : 'Lançamentos'),
          leading: somiaMenuLeading(context),
        ),
        floatingActionButton: const SomiaQuickActions(),
        body: BlocConsumer<TransactionsCubit, TransactionsState>(
          listener: (context, state) {
            if (!_openedInitial &&
                !state.loading &&
                state.error == null &&
                (widget.initialCreateType == 'income' ||
                    widget.initialCreateType == 'expense')) {
              _openedInitial = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _edit();
              });
            }
          },
          builder: (context, state) {
            if (state.loading &&
                state.accounts.isEmpty &&
                state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                  child: TextButton(
                onPressed: context.read<TransactionsCubit>().load,
                child: Text('${state.error} Tentar novamente'),
              ));
            }
            return Column(children: [
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        MonthSelector(
                            month: referenceMonth.value,
                            onChanged: (month) {
                              if (month == referenceMonth.value) {
                                _monthChanged();
                              } else {
                                referenceMonth.select(month);
                              }
                            }),
                        OutlinedButton.icon(
                            onPressed: () => _openFilters(state),
                            icon: const Icon(Icons.tune),
                            label: const Text('Filtros')),
                        if (_customPeriod)
                          Text(_range == null
                              ? 'Todos os meses'
                              : '${_dateLabel(_range!.start)} – ${_dateLabel(_range!.end)}'),
                      ])),
              Expanded(
                  child: state.items.isEmpty
                      ? Center(
                          child: Text(widget.sectionType ==
                                  TransactionType.income
                              ? 'Nenhuma receita para estes filtros.'
                              : widget.sectionType == TransactionType.expense
                                  ? 'Nenhuma despesa para estes filtros.'
                                  : 'Nenhum lançamento para estes filtros.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) =>
                              _itemTile(state.items[index]),
                        )),
            ]);
          },
        ),
      );

  Widget _filters(TransactionsState state) => ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.60),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.sectionType == null) ...[
                  ChoiceChip(
                      label: const Text('Todos'),
                      selected: _type == null,
                      onSelected: (_) {
                        setState(() {
                          _type = null;
                          _categoryId = null;
                          _subcategoryId = null;
                        });
                        _apply();
                      }),
                  for (final type in TransactionType.values)
                    ChoiceChip(
                        label: Text(type.label),
                        selected: _type == type,
                        onSelected: (_) {
                          setState(() {
                            _type = type;
                            _categoryId = null;
                            _subcategoryId = null;
                          });
                          _apply();
                        }),
                ],
                SizedBox(
                    width: 220,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _accountId ?? '',
                      hint: const Text('Conta'),
                      items: [
                        const DropdownMenuItem(
                            value: '', child: Text('Todas as contas')),
                        for (final account in state.accounts)
                          DropdownMenuItem(
                              value: account.id,
                              child: Text(account.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (id) {
                        setState(() => _accountId = id == '' ? null : id);
                        _apply();
                      },
                    )),
                SizedBox(
                    width: 220,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _categoryId ?? '',
                      hint: const Text('Categoria'),
                      items: [
                        const DropdownMenuItem(
                            value: '', child: Text('Todas as categorias')),
                        for (final category in state.categories.where((c) =>
                            c.parentId == null &&
                            (_type == null || c.type.name == _type!.name)))
                          DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: (id) {
                        setState(() {
                          _categoryId = id == '' ? null : id;
                          _subcategoryId = null;
                        });
                        _apply();
                      },
                    )),
                SizedBox(
                    width: 220,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _subcategoryId ?? '',
                      hint: const Text('Subcategoria'),
                      items: [
                        const DropdownMenuItem(
                            value: '', child: Text('Todas as subcategorias')),
                        for (final category in state.categories.where((c) =>
                            c.parentId == _categoryId && _categoryId != null))
                          DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: _categoryId == null
                          ? null
                          : (id) {
                              setState(
                                  () => _subcategoryId = id == '' ? null : id);
                              _apply();
                            },
                    )),
                SizedBox(
                    width: 220,
                    child: DropdownButton<TransactionStatus>(
                      isExpanded: true,
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                            value: TransactionStatus.all,
                            child: Text('Todos os estados')),
                        DropdownMenuItem(
                            value: TransactionStatus.effective,
                            child: Text('Efetivados')),
                        DropdownMenuItem(
                            value: TransactionStatus.pending,
                            child: Text('Pendentes')),
                      ],
                      onChanged: (status) {
                        if (status != null) {
                          setState(() => _status = status);
                          _apply();
                        }
                      },
                    )),
                SizedBox(
                    width: 220,
                    child: DropdownButton<TransactionDateField>(
                      isExpanded: true,
                      value: _dateField,
                      items: const [
                        DropdownMenuItem(
                            value: TransactionDateField.posted,
                            child: Text('Filtrar lançamento')),
                        DropdownMenuItem(
                            value: TransactionDateField.due,
                            child: Text('Filtrar vencimento')),
                        DropdownMenuItem(
                            value: TransactionDateField.effective,
                            child: Text('Filtrar efetivação')),
                      ],
                      onChanged: (field) {
                        if (field != null) {
                          setState(() => _dateField = field);
                          _apply();
                        }
                      },
                    )),
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_range == null
                      ? 'Período'
                      : '${_dateLabel(_range!.start)} – ${_dateLabel(_range!.end)}'),
                ),
                if (_range != null)
                  IconButton(
                    tooltip: 'Limpar período',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _range = _monthRange;
                        _customPeriod = false;
                      });
                      _apply();
                    },
                  ),
              ],
            )),
      );

  Widget _itemTile(FinancialTransaction item) {
    final categories = context.read<TransactionsCubit>().state.categories;
    final category =
        categories.where((c) => c.id == item.categoryId).firstOrNull;
    final parent =
        categories.where((c) => c.id == category?.parentId).firstOrNull;
    final busy = _changingStatus.contains(item.id);
    return MovementListRow(
      id: item.id,
      description: item.description,
      account: item.accountName,
      amount:
          '${item.type == TransactionType.income ? '+' : '-'}${MoneyMinor.display(item.amountMinor, item.currencyCode)}',
      dueDate: item.dueDate ?? item.date,
      effectiveDate: item.effectiveDate,
      effective: item.isEffective,
      busy: busy,
      color: item.type == TransactionType.income
          ? SomiaColors.green
          : SomiaColors.red,
      effectiveLabel:
          item.type == TransactionType.income ? 'Receber hoje' : 'Pagar hoje',
      tags: [
        if (parent != null) parent.name,
        if (item.categoryName != null) item.categoryName!
      ],
      onEffective: () => _quickEffective(item),
      onPending: () => _markPending(item),
      onAmount: () => _editAmount(item),
      onEdit: () => _edit(item),
      menu: PopupMenuButton<String>(
        key: ValueKey('movement-menu-${item.id}'),
        enabled: !busy,
        tooltip: 'Ações do lançamento',
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (action) {
          if (action == 'edit') _edit(item);
          if (action == 'delete') _delete(item);
          if (action == 'pending') _markPending(item);
          if (action == 'date' && item.effectiveDate != null) {
            _changeDate(item.id, item.effectiveDate!, pick: true);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
          if (item.effectiveDate != null) ...[
            const PopupMenuItem(value: 'date', child: Text('Ajustar data')),
            const PopupMenuItem(
                value: 'pending', child: Text('Marcar como pendente')),
          ],
          const PopupMenuItem(value: 'delete', child: Text('Excluir')),
        ],
      ),
    );
  }
}

class TransactionForm extends StatefulWidget {
  const TransactionForm(
      {super.key,
      required this.accounts,
      required this.categories,
      this.item,
      this.fixedType,
      this.initialType = TransactionType.expense});
  final FinancialTransaction? item;
  final TransactionType? fixedType;
  final TransactionType initialType;
  final List<Account> accounts;
  final List<FinanceCategory> categories;

  @override
  State<TransactionForm> createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  final _descriptionFocus = FocusNode();
  final _amountFocus = FocusNode();
  late TransactionType _type;
  late DateTime _date;
  late DateTime _dueDate;
  DateTime? _effectiveDate;
  late bool _isEffective;
  String? _accountId;
  String? _categoryId;
  String? _subcategoryId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _description = TextEditingController(text: item?.description ?? '');
    _amount =
        TextEditingController(text: MoneyMinor.plain(item?.amountMinor ?? 0));
    _type = item?.type ?? widget.initialType;
    _date = item?.date ?? DateTime.now();
    _dueDate = item?.dueDate ?? _date;
    _effectiveDate = item?.effectiveDate;
    _isEffective = item == null || item.effectiveDate != null;
    _accountId = item?.accountId ?? _availableAccounts.firstOrNull?.id;
    final selected = widget.categories
        .where((category) => category.id == item?.categoryId)
        .firstOrNull;
    _categoryId = selected?.parentId ?? selected?.id;
    _subcategoryId = selected?.parentId == null ? null : selected?.id;
  }

  List<Account> get _availableAccounts => widget.accounts
      .where((account) =>
          !account.isArchived || account.id == widget.item?.accountId)
      .toList();

  @override
  void dispose() {
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String field) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: field == 'posted'
            ? _date
            : field == 'due'
                ? _dueDate
                : _effectiveDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null && mounted) {
      setState(() {
        if (field == 'posted') {
          _date = picked;
        } else if (field == 'due') {
          _dueDate = picked;
        } else {
          _effectiveDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    var effective = _isEffective ? _effectiveDate ?? DateTime.now() : null;
    if (_isEffective &&
        widget.item?.effectiveDate == null &&
        !DateUtils.isSameDay(_dueDate, DateTime.now())) {
      effective = await chooseEffectuationDate(context, _dueDate);
      if (effective == null || !mounted) return;
    }
    if (!mounted) return;
    Navigator.pop(
        context,
        TransactionDraft(
          description: _description.text.trim(),
          type: _type,
          amountMinor: MoneyMinor.parse(_amount.text),
          date: _date,
          dueDate: _dueDate,
          effectiveDate: effective,
          isEffective: _isEffective,
          accountId: _accountId!,
          categoryId: _subcategoryId ?? _categoryId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final roots = widget.categories
        .where((category) =>
            category.parentId == null &&
            category.type.name == _type.name &&
            (!category.isArchived || category.id == _categoryId))
        .toList();
    final children = widget.categories
        .where((category) =>
            category.parentId == _categoryId &&
            _categoryId != null &&
            (!category.isArchived || category.id == _subcategoryId))
        .toList();
    final kind = _type == TransactionType.income ? 'receita' : 'despesa';
    return UnsavedChangesGuard(
        value: () => (
              _description.text,
              _amount.text,
              _type,
              _date,
              _dueDate,
              _effectiveDate,
              _isEffective,
              _accountId,
              _categoryId,
              _subcategoryId
            ),
        changes: [_description, _amount],
        builder: (context, cancel) => MovementFormFrame(
              onCancel: cancel,
              title: widget.item == null ? 'Nova $kind' : 'Editar $kind',
              onSave: _submit,
              child: Form(
                key: _formKey,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      TextFormField(
                          controller: _description,
                          focusNode: _descriptionFocus,
                          autofocus: widget.item == null &&
                              usesFullScreenMovementForm(context),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            _amountFocus.requestFocus();
                            _amount.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _amount.text.length);
                          },
                          scrollPadding: const EdgeInsets.all(100),
                          decoration:
                              const InputDecoration(labelText: 'Descrição'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Informe a descrição.'
                                  : null),
                      MonetaryCalculatorField(
                          controller: _amount,
                          focusNode: _amountFocus,
                          currencyCode: _availableAccounts
                                  .where((a) => a.id == _accountId)
                                  .firstOrNull
                                  ?.currencyCode ??
                              'BRL'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _accountId,
                        decoration: const InputDecoration(labelText: 'Conta'),
                        items: _availableAccounts
                            .map((account) => DropdownMenuItem(
                                  value: account.id,
                                  child: Text(
                                      '${account.name}${account.isArchived ? ' (arquivada)' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        validator: (value) =>
                            value == null ? 'Cadastre uma conta ativa.' : null,
                        onChanged: (id) => setState(() => _accountId = id),
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey('category-${_type.name}'),
                        initialValue: _categoryId,
                        decoration:
                            const InputDecoration(labelText: 'Categoria'),
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('Sem categoria')),
                          for (final category in roots)
                            DropdownMenuItem(
                                value: category.id,
                                child: Text(
                                    '${category.name}'
                                    '${category.isArchived ? ' (arquivada)' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: (id) => setState(() {
                          _categoryId = id == null || id.isEmpty ? null : id;
                          _subcategoryId = null;
                        }),
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey('subcategory-${_type.name}-$_categoryId'),
                        initialValue: _subcategoryId,
                        decoration:
                            const InputDecoration(labelText: 'Subcategoria'),
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('Nenhuma')),
                          for (final category in children)
                            DropdownMenuItem(
                                value: category.id,
                                child: Text(
                                    '${category.name}'
                                    '${category.isArchived ? ' (arquivada)' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: _categoryId == null
                            ? null
                            : (id) => setState(() => _subcategoryId =
                                id == null || id.isEmpty ? null : id),
                      ),
                      MovementDateFields(
                        posted: _date,
                        due: _dueDate,
                        onPosted: () => _pickDate('posted'),
                        onDue: () => _pickDate('due'),
                      ),
                      SwitchListTile(
                        title: Text(_type == TransactionType.income
                            ? 'Recebido'
                            : 'Pago'),
                        subtitle: const Text(
                            'A data determina quando entra no saldo atual'),
                        value: _isEffective,
                        onChanged: (value) =>
                            setState(() => _isEffective = value),
                      ),
                      if (_isEffective)
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Data de efetivação'),
                            subtitle: Text(
                                _dateLabel(_effectiveDate ?? DateTime.now())),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _pickDate('effective')),
                      if (widget.fixedType == null)
                        ExpansionTile(
                          title: const Text('Mais detalhes'),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            DropdownButtonFormField<TransactionType>(
                              isExpanded: true,
                              initialValue: _type,
                              decoration:
                                  const InputDecoration(labelText: 'Tipo'),
                              items: TransactionType.values
                                  .map((type) => DropdownMenuItem(
                                      value: type, child: Text(type.label)))
                                  .toList(),
                              onChanged: (type) {
                                if (type != null) {
                                  setState(() {
                                    _type = type;
                                    _categoryId = null;
                                    _subcategoryId = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ]),
              ),
            ));
  }
}
