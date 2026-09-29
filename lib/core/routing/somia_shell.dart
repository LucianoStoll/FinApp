import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

class SomiaShell extends StatelessWidget {
  const SomiaShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home), label: 'Resumo'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long), label: 'Lançamentos'),
    NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet), label: 'Contas'),
    NavigationDestination(icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
  ];
  static const _paths = [AppRoutes.dashboardPath, AppRoutes.transactionsPath,
    AppRoutes.accountsPath, AppRoutes.settingsPath];

  @override
  Widget build(BuildContext context) {
    final index = location == AppRoutes.transactionsPath ? 1
        : location == AppRoutes.accountsPath ? 2
        : location == AppRoutes.settingsPath ? 3 : 0;
    void select(int value) => context.go(_paths[value]);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 800) {
        return Scaffold(body: Row(children: [
          NavigationRail(selectedIndex: index, onDestinationSelected: select,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Resumo')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), label: Text('Lançamentos')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: Text('Contas')),
              NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Ajustes')),
            ]),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ]));
      }
      return Scaffold(body: child,
        bottomNavigationBar: NavigationBar(selectedIndex: index,
          onDestinationSelected: select, destinations: _destinations));
    });
  }
}

class SomiaQuickActions extends StatelessWidget {
  const SomiaQuickActions({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Adicionar lançamento ou transferência',
    icon: const Icon(Icons.add),
    iconColor: Theme.of(context).colorScheme.onPrimary,
    style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary,
      minimumSize: const Size(56, 56)),
    onSelected: (action) {
      if (action == 'transfer') {
        context.go('${AppRoutes.transfersPath}?create=1');
      } else {
        context.go('${AppRoutes.transactionsPath}?create=$action');
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'income', child: ListTile(
        leading: Icon(Icons.south_west), title: Text('Receita'))),
      PopupMenuItem(value: 'expense', child: ListTile(
        leading: Icon(Icons.north_east), title: Text('Despesa'))),
      PopupMenuItem(value: 'transfer', child: ListTile(
        leading: Icon(Icons.swap_horiz), title: Text('Transferência'))),
    ],
  );
}
