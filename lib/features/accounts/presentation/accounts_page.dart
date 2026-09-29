import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import '../domain/money_minor.dart';
import 'accounts_cubit.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AccountsCubit(getIt<AccountsRepository>()),
        child: const _AccountsView(),
      );
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  Future<void> _edit(BuildContext context, [Account? account]) async {
    final draft = await showDialog<AccountDraft>(
      context: context,
      builder: (_) => _AccountDialog(account: account),
    );
    if (draft == null || !context.mounted) return;
    try {
      await context.read<AccountsCubit>().save(draft, id: account?.id);
    } catch (error) {
      if (context.mounted) _message(context, _errorMessage(error));
    }
  }

  Future<void> _archive(BuildContext context, Account account) async {
    try {
      await context.read<AccountsCubit>().setArchived(account);
    } catch (error) {
      if (context.mounted) _message(context, _errorMessage(error));
    }
  }

  String _errorMessage(Object error) {
    if (error is FormatException) return error.message;
    if (error is StateError) return error.message;
    return 'Não foi possível salvar a conta.';
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Contas'),
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova conta'),
          ),
        ),
        body: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            if (state.loading && state.accounts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!),
                    TextButton(
                      onPressed: context.read<AccountsCubit>().load,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }
            if (state.accounts.isEmpty) {
              return const Center(child: Text('Nenhuma conta cadastrada.'));
            }
            final totals = <String, (int, int)>{};
            for (final account in state.accounts) {
              final current = totals[account.currencyCode] ?? (0, 0);
              totals[account.currencyCode] = (
                current.$1 + account.currentBalanceMinor,
                current.$2 + account.projectedBalanceMinor,
              );
            }
            final currencies = totals.keys.toList()..sort();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: state.accounts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Text('Saldos consolidados',
                          style: Theme.of(context).textTheme.titleMedium)),
                      for (final currency in currencies)
                        Card(child: ListTile(
                          title: Text(currency),
                          subtitle: Text('Atual: ${MoneyMinor.display(totals[currency]!.$1, currency)}'
                            '\nProjetado (todas as pendências): '
                            '${MoneyMinor.display(totals[currency]!.$2, currency)}'),
                          isThreeLine: true,
                        )),
                      const SizedBox(height: 8),
                    ],
                  );
                }
                final account = state.accounts[index - 1];
                return Card(
                  child: ListTile(
                    title: Text(account.name),
                    subtitle: Text(
                      '${account.type.label} · ${account.currencyCode}'
                      '${account.isArchived ? ' · Arquivada' : ''}'
                      '${account.includeInAnalytics ? '' : ' · Fora das análises'}'
                      '\nAtual: ${MoneyMinor.display(account.currentBalanceMinor, account.currencyCode)}'
                      '\nProjetado: ${MoneyMinor.display(account.projectedBalanceMinor, account.currencyCode)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações da conta',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _edit(context, account);
                        } else {
                          _archive(context, account);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(account.isArchived ? 'Reativar' : 'Arquivar'),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    leading: Icon(account.type == AccountType.cash
                        ? Icons.account_balance_wallet_outlined
                        : Icons.account_balance_outlined),
                    dense: false,
                    onTap: () => _edit(context, account),
                  ),
                );
              },
            );
          },
        ),
      );
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({this.account});
  final Account? account;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _currency;
  late final TextEditingController _initialBalance;
  late AccountType _type;
  late bool _includeInAnalytics;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.name ?? '');
    _currency = TextEditingController(text: account?.currencyCode ?? 'BRL');
    _initialBalance = TextEditingController(
      text: MoneyMinor.plain(account?.initialBalanceMinor ?? 0),
    );
    _type = account?.type ?? AccountType.checking;
    _includeInAnalytics = account?.includeInAnalytics ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _currency.dispose();
    _initialBalance.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AccountDraft(
        name: _name.text.trim(),
        type: _type,
        currencyCode: _currency.text.trim().toUpperCase(),
        initialBalanceMinor: MoneyMinor.parse(_initialBalance.text),
        includeInAnalytics: _includeInAnalytics,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.account == null ? 'Nova conta' : 'Editar conta'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome.' : null,
                  ),
                  DropdownButtonFormField<AccountType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: AccountType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ))
                        .toList(),
                    onChanged: (type) {
                      if (type != null) setState(() => _type = type);
                    },
                  ),
                  TextFormField(
                    controller: _currency,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Moeda (ISO 4217)'),
                    validator: (value) => RegExp(r'^[A-Za-z]{3}$')
                            .hasMatch(value?.trim() ?? '')
                        ? null : 'Use três letras, como BRL.',
                  ),
                  TextFormField(
                    controller: _initialBalance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Saldo inicial'),
                    validator: (value) {
                      try {
                        MoneyMinor.parse(value ?? '');
                        return null;
                      } on FormatException catch (error) {
                        return error.message;
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Incluir em análises'),
                    value: _includeInAnalytics,
                    onChanged: (value) => setState(() => _includeInAnalytics = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: _submit, child: const Text('Salvar')),
        ],
      );
}
