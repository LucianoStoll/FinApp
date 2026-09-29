import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../accounts/domain/money_minor.dart';
import '../../domain/dashboard_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../dashboard_cubit.dart';

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DashboardCubit(getIt<DashboardRepository>()),
    child: const _DashboardView(),
  );
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DashboardCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FinApp'), actions: [
      IconButton(tooltip: 'Atualizar resumo', icon: const Icon(Icons.refresh),
        onPressed: context.read<DashboardCubit>().load),
    ]),
    body: SafeArea(child: BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.loading && state.summary == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.summary == null) {
          return Center(child: TextButton(
            onPressed: context.read<DashboardCubit>().load,
            child: Text('${state.error} Tentar novamente'),
          ));
        }
        return RefreshIndicator(
          onRefresh: context.read<DashboardCubit>().load,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth > 1100 ? 1100.0
                : constraints.maxWidth;
            return ListView(children: [
              Center(child: SizedBox(width: width, child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seu resumo', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text('Visão do mês e das suas contas',
                      style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    _monthSelector(context, state.month),
                    const SizedBox(height: 16),
                    if (state.loading) const LinearProgressIndicator(),
                    if (state.error != null) Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(state.error!)),
                    if (state.summary != null)
                      ..._sections(context, state.summary!, width - 40),
                    const SizedBox(height: 24),
                    Text('Acessar', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      _link(context, 'Contas', Icons.account_balance_wallet_outlined,
                        AppRoutes.accounts),
                      _link(context, 'Categorias', Icons.category_outlined,
                        AppRoutes.categories),
                      _link(context, 'Receitas e despesas', Icons.receipt_long_outlined,
                        AppRoutes.transactions),
                      _link(context, 'Transferências', Icons.swap_horiz,
                        AppRoutes.transfers),
                    ]),
                  ],
                ),
              ))),
            ]);
          }),
        );
      },
    )),
  );

  Widget _monthSelector(BuildContext context, DateTime month) => Row(children: [
    IconButton(tooltip: 'Mês anterior', icon: const Icon(Icons.chevron_left),
      onPressed: () => context.read<DashboardCubit>().moveMonth(-1)),
    Text('${_months[month.month - 1]} de ${month.year}',
      style: Theme.of(context).textTheme.titleMedium),
    IconButton(tooltip: 'Próximo mês', icon: const Icon(Icons.chevron_right),
      onPressed: () => context.read<DashboardCubit>().moveMonth(1)),
  ]);

  List<Widget> _sections(BuildContext context, DashboardSummary summary,
      double availableWidth) {
    if (summary.isEmpty) {
      return [const Card(child: Padding(padding: EdgeInsets.all(24),
        child: Text('Cadastre uma conta para começar seu resumo.')))];
    }
    final cardWidth = availableWidth >= 720
        ? (availableWidth - 12) / 2 : availableWidth;
    return [
      for (final currency in summary.currencies) ...[
        Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(currency.currencyCode,
            style: Theme.of(context).textTheme.titleMedium)),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _metric(context, 'Saldo total', currency.currentBalanceMinor,
            currency.currencyCode, Icons.account_balance_wallet_outlined, cardWidth),
          _metric(context, 'Saldo projetado', currency.projectedBalanceMinor,
            currency.currencyCode, Icons.trending_up, cardWidth),
          _metric(context, 'Receitas do mês', currency.incomeMinor,
            currency.currencyCode, Icons.south_west, cardWidth),
          _metric(context, 'Despesas do mês', currency.expenseMinor,
            currency.currencyCode, Icons.north_east, cardWidth),
        ]),
      ],
      const SizedBox(height: 28),
      Text('Movimentações recentes',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (summary.recent.isEmpty)
        const Card(child: ListTile(title: Text('Nenhuma movimentação ainda.')))
      else
        for (final item in summary.recent)
          Card(child: ListTile(
            leading: Icon(switch (item.type) {
              DashboardActivityType.income => Icons.south_west,
              DashboardActivityType.expense => Icons.north_east,
              DashboardActivityType.transfer => Icons.swap_horiz,
            }),
            title: Text(item.description),
            subtitle: Text('${item.accountLabel} · ${_dateLabel(item.date)}'
              '${item.isEffective ? '' : ' · Pendente'}'),
            trailing: Text('${item.type == DashboardActivityType.income ? '+' :
              item.type == DashboardActivityType.expense ? '-' : ''}'
              '${MoneyMinor.display(item.amountMinor, item.currencyCode)}'),
            onTap: () => context.goNamed(item.type == DashboardActivityType.transfer
              ? AppRoutes.transfers : AppRoutes.transactions),
          )),
    ];
  }

  Widget _metric(BuildContext context, String title, int amount,
      String currency, IconData icon, double width) => SizedBox(width: width,
    child: Card(child: Padding(padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 22),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 5),
        Text(MoneyMinor.display(amount, currency),
          style: Theme.of(context).textTheme.titleLarge),
      ]))));

  Widget _link(BuildContext context, String label, IconData icon, String route) =>
      OutlinedButton.icon(onPressed: () => context.goNamed(route),
        icon: Icon(icon), label: Text(label));
}
