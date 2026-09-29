import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/somia_shell.dart';
import '../../../accounts/domain/money_minor.dart';
import '../../domain/dashboard_repository.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../dashboard_cubit.dart';

const _months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
const _chartColors = [Color(0xFFE4A1AC), Color(0xFFA4CDB9),
  Color(0xFFBDB5E2), Color(0xFF8FB4D9), Color(0xFFE2C49C)];

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
    if (state == AppLifecycleState.resumed) context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Somia'), actions: [
      IconButton(tooltip: 'Atualizar resumo', icon: const Icon(Icons.refresh),
        onPressed: context.read<DashboardCubit>().load),
    ]),
    floatingActionButton: const SomiaQuickActions(),
    body: BlocBuilder<DashboardCubit, DashboardState>(builder: (context, state) {
      if (state.loading && state.summary == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.summary == null) {
        return Center(child: TextButton(
          onPressed: context.read<DashboardCubit>().load,
          child: Text('${state.error ?? 'Resumo indisponível.'} Tentar novamente')));
      }
      return RefreshIndicator(onRefresh: context.read<DashboardCubit>().load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(tooltip: 'Mês anterior', icon: const Icon(Icons.chevron_left),
                  onPressed: () => context.read<DashboardCubit>().moveMonth(-1)),
                Flexible(child: Text('${_months[state.month.month - 1]} ${state.month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium)),
                IconButton(tooltip: 'Próximo mês', icon: const Icon(Icons.chevron_right),
                  onPressed: () => context.read<DashboardCubit>().moveMonth(1)),
              ]),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) Text(state.error!),
              if (state.summary!.currencies.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24),
                  child: Text('Cadastre uma conta para começar seu resumo.'))),
              for (final currency in state.summary!.currencies)
                _currencySection(context, currency),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('Últimos lançamentos',
                  style: Theme.of(context).textTheme.titleLarge)),
                TextButton(onPressed: () => context.goNamed(AppRoutes.transactions),
                  child: const Text('Ver todos')),
              ]),
              if (state.summary!.recent.isEmpty)
                const Card(child: ListTile(title: Text('Nenhuma movimentação ainda.'))),
              for (final item in state.summary!.recent)
                Card(child: ListTile(
                  leading: CircleAvatar(child: Icon(switch (item.type) {
                    DashboardActivityType.income => Icons.south_west,
                    DashboardActivityType.expense => Icons.north_east,
                    DashboardActivityType.transfer => Icons.swap_horiz,
                  })),
                  title: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${item.accountLabel} · ${item.date.day.toString().padLeft(2, '0')}/'
                    '${item.date.month.toString().padLeft(2, '0')}/${item.date.year}'
                    '${item.isEffective ? '' : ' · Pendente'}'),
                  trailing: Text('${item.type == DashboardActivityType.income ? '+' :
                    item.type == DashboardActivityType.expense ? '-' : ''}'
                    '${MoneyMinor.display(item.amountMinor, item.currencyCode)}'),
                  onTap: () => context.goNamed(item.type == DashboardActivityType.transfer
                    ? AppRoutes.transfers : AppRoutes.transactions),
                )),
            ])))],
        )));
    }),
  );

  Widget _currencySection(BuildContext context, DashboardCurrencySummary currency) {
    final scheme = Theme.of(context).colorScheme;
    final code = currency.currencyCode;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (code != 'BRL' || context.read<DashboardCubit>().state.summary!.currencies.length > 1)
        Padding(padding: const EdgeInsets.only(top: 18, left: 8),
          child: Text(code, style: Theme.of(context).textTheme.titleMedium)),
      Card(child: Padding(padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resultado do mês'),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(MoneyMinor.display(currency.monthlyResultMinor, code),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.bold))),
          const Divider(height: 32),
          Row(children: [
            Expanded(child: _smallMetric(context, 'Receitas',
              currency.incomeMinor, code, const Color(0xFFA4CDB9))),
            const SizedBox(width: 14),
            Expanded(child: _smallMetric(context, 'Despesas',
              currency.expenseMinor, code, const Color(0xFFE4A1AC))),
          ]),
        ]))),
      Card(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gastos por categoria', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (currency.expensesByCategory.isEmpty)
            const Text('Nenhuma despesa efetivada neste mês.')
          else LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 480;
            final chart = SizedBox(width: 160, height: 160,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(160, 160),
                  painter: _DonutPainter(currency.expensesByCategory)),
                Padding(padding: const EdgeInsets.all(35),
                  child: Text(MoneyMinor.display(currency.expenseMinor, code),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium)),
              ]));
            final legend = Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < currency.expensesByCategory.length; i++)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(radius: 5,
                        backgroundColor: _chartColors[i % _chartColors.length]),
                      const SizedBox(width: 8),
                      Flexible(child: Text(currency.expensesByCategory[i].name,
                        overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('${currency.expenseMinor == 0 ? 0 :
                        (currency.expensesByCategory[i].amountMinor * 100 /
                        currency.expenseMinor).round()}%'),
                    ])),
              ]);
            return wide ? Row(children: [chart, const SizedBox(width: 20),
              Expanded(child: legend)]) : Column(children: [
              chart, const SizedBox(height: 12), legend]);
          }),
        ]))),
      Card(child: Padding(padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Saldos até o fim do mês', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('Saldo total: ${MoneyMinor.display(currency.currentBalanceMinor, code)}'),
          const SizedBox(height: 5),
          Text('Saldo projetado: ${MoneyMinor.display(currency.projectedBalanceMinor, code)}'),
        ]))),
    ]);
  }

  Widget _smallMetric(BuildContext context, String label, int amount,
      String code, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(MoneyMinor.display(amount, code),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color, fontWeight: FontWeight.bold))),
    ]);
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.categories);
  final List<DashboardCategoryExpense> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.amountMinor);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    var start = -math.pi / 2;
    for (var i = 0; i < categories.length; i++) {
      final sweep = categories[i].amountMinor / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, Paint()
        ..color = _chartColors[i % _chartColors.length]
        ..style = PaintingStyle.stroke ..strokeWidth = 20);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
    oldDelegate.categories != categories;
}
