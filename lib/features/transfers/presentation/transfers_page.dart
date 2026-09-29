import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/routing/somia_shell.dart';
import '../../../core/widgets/effectuation_date_dialog.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/accounts_repository.dart';
import '../../accounts/domain/money_minor.dart';
import '../domain/transfer.dart';
import '../domain/transfers_repository.dart';
import 'transfers_cubit.dart';

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key, this.startCreate = false});
  final bool startCreate;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransfersCubit(getIt<TransfersRepository>(),
      getIt<AccountsRepository>()),
    child: _TransfersView(startCreate: startCreate),
  );
}

class _TransfersView extends StatefulWidget {
  const _TransfersView({required this.startCreate});
  final bool startCreate;

  @override
  State<_TransfersView> createState() => _TransfersViewState();
}

class _TransfersViewState extends State<_TransfersView> {
  bool _openedInitial = false;

  Future<void> _edit(BuildContext context, [Transfer? item]) async {
    final cubit = context.read<TransfersCubit>();
    final draft = await showDialog<TransferDraft>(context: context,
      builder: (_) => _TransferDialog(item: item, accounts: cubit.state.accounts));
    if (!context.mounted) return;
    if (draft == null) {
      if (item == null && widget.startCreate) context.go('/transfers');
      return;
    }
    try {
      await cubit.save(draft, id: item?.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
    if (context.mounted && item == null && widget.startCreate) {
      context.go('/transfers');
    }
  }

  Future<void> _delete(BuildContext context, Transfer item) async {
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Excluir transferência?'),
        content: const Text('O valor sairá dos saldos das duas contas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Excluir')),
        ],
      ));
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<TransfersCubit>().delete(item.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _setEffective(BuildContext context, Transfer item) async {
    final chosen = await chooseEffectuationDate(context,
      item.dueDate ?? item.date);
    if (chosen == null || !context.mounted) return;
    try {
      await context.read<TransfersCubit>().setEffective(item.id,
        effective: true, effectiveDate: chosen);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    final message = error is FormatException ? error.message
        : error is StateError ? error.message
        : 'Não foi possível salvar a transferência.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transferências'),
      leading: somiaMenuLeading(context)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(context), icon: const Icon(Icons.add),
      label: const Text('Nova transferência'),
    ),
    body: BlocConsumer<TransfersCubit, TransfersState>(
      listener: (context, state) {
        if (widget.startCreate && !_openedInitial && !state.loading &&
            state.error == null) {
          _openedInitial = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _edit(context);
          });
        }
      }, builder: (context, state) {
      if (state.loading && state.accounts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.error != null) {
        return Center(child: TextButton(
          onPressed: context.read<TransfersCubit>().load,
          child: Text('${state.error} Tentar novamente'),
        ));
      }
      if (state.items.isEmpty) {
        return const Center(child: Text('Nenhuma transferência cadastrada.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return Card(child: ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text('${item.sourceAccountName} → ${item.destinationAccountName}',
              maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lançamento ${_dateLabel(item.date)} · '
                'Vencimento ${_dateLabel(item.dueDate ?? item.date)} · '
                '${item.effectiveDate == null ? 'Pendente' :
                  item.isEffective ? 'Efetivada ${_dateLabel(item.effectiveDate!)}'
                    : 'Agendada ${_dateLabel(item.effectiveDate!)}'}'),
              Text(MoneyMinor.display(item.amountMinor, item.currencyCode)),
              if (!item.isEffective)
                TextButton.icon(onPressed: () => _setEffective(context, item),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Efetivar')),
            ]),
            trailing: PopupMenuButton<String>(tooltip: 'Ações da transferência',
                onSelected: (action) => action == 'edit'
                    ? _edit(context, item) : _delete(context, item),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ]),
            onTap: () => _edit(context, item),
          ));
        },
      );
    }),
  );
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.accounts, this.item});

  final List<Account> accounts;
  final Transfer? item;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  String? _sourceId;
  String? _destinationId;
  late DateTime _date;
  late DateTime _dueDate;
  DateTime? _effectiveDate;
  late bool _isEffective;

  List<Account> get _sources => widget.accounts.where((a) =>
      !a.isArchived || a.id == widget.item?.sourceAccountId).toList();

  List<Account> get _destinations {
    final source = widget.accounts.where((a) => a.id == _sourceId).firstOrNull;
    return widget.accounts.where((a) => a.id != _sourceId &&
      a.currencyCode == source?.currencyCode &&
      (!a.isArchived || a.id == widget.item?.destinationAccountId)).toList();
  }

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: MoneyMinor.plain(widget.item?.amountMinor ?? 0));
    _sourceId = widget.item?.sourceAccountId ?? _sources.firstOrNull?.id;
    _destinationId = widget.item?.destinationAccountId ?? _destinations.firstOrNull?.id;
    _date = widget.item?.date ?? DateTime.now();
    _dueDate = widget.item?.dueDate ?? _date;
    _effectiveDate = widget.item?.effectiveDate;
    _isEffective = widget.item == null || widget.item!.effectiveDate != null;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String field) async {
    final picked = await showDatePicker(context: context,
      initialDate: field == 'posted' ? _date : field == 'due' ? _dueDate
        : _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() {
      if (field == 'posted') { _date = picked; }
      else if (field == 'due') { _dueDate = picked; }
      else { _effectiveDate = picked; }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    var effective = _isEffective ? _effectiveDate ?? DateTime.now() : null;
    if (_isEffective && widget.item?.effectiveDate == null &&
        DateUtils.dateOnly(_dueDate).isAfter(DateUtils.dateOnly(DateTime.now()))) {
      effective = await chooseEffectuationDate(context, _dueDate);
      if (effective == null || !mounted) return;
    }
    if (!mounted) return;
    Navigator.pop(context, TransferDraft(sourceAccountId: _sourceId!,
      destinationAccountId: _destinationId!, amountMinor: MoneyMinor.parse(_amount.text),
      date: _date, dueDate: _dueDate, effectiveDate: effective,
      isEffective: _isEffective));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Nova transferência' : 'Editar transferência'),
    content: SizedBox(width: 440, child: Form(key: _formKey,
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(key: ValueKey('source-$_sourceId'),
            isExpanded: true,
            initialValue: _sourceId,
            decoration: const InputDecoration(labelText: 'Conta de origem'),
            items: _sources.map((a) => DropdownMenuItem(value: a.id,
              child: Text('${a.name} (${a.currencyCode})'
                '${a.isArchived ? ' · arquivada' : ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
            validator: (id) => id == null ? 'Selecione uma conta de origem.' : null,
            onChanged: (id) => setState(() {
              _sourceId = id;
              if (!_destinations.any((a) => a.id == _destinationId)) {
                _destinationId = _destinations.firstOrNull?.id;
              }
            }),
          ),
          DropdownButtonFormField<String>(key: ValueKey('destination-$_sourceId'),
            isExpanded: true,
            initialValue: _destinationId,
            decoration: const InputDecoration(labelText: 'Conta de destino'),
            items: _destinations.map((a) => DropdownMenuItem(value: a.id,
              child: Text('${a.name} (${a.currencyCode})'
                '${a.isArchived ? ' · arquivada' : ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
            validator: (id) => id == null ? 'Selecione outra conta da mesma moeda.' : null,
            onChanged: (id) => setState(() => _destinationId = id),
          ),
          TextFormField(controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor'),
            validator: (value) {
              try {
                return MoneyMinor.parse(value ?? '') > 0 ? null
                    : 'O valor deve ser maior que zero.';
              } on FormatException catch (error) { return error.message; }
            }),
          ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Data de lançamento'),
            subtitle: Text(_dateLabel(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate('posted')),
          ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Vencimento'), subtitle: Text(_dateLabel(_dueDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate('due')),
          SwitchListTile(title: const Text('Informar efetivação'),
            subtitle: const Text('A data movimenta as duas contas'),
            value: _isEffective,
            onChanged: (value) => setState(() => _isEffective = value)),
          if (_isEffective) ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Data de efetivação'),
            subtitle: Text(_dateLabel(_effectiveDate ?? DateTime.now())),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate('effective')),
        ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: _submit, child: const Text('Salvar')),
    ],
  );
}
