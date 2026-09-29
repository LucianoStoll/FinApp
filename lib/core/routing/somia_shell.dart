import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'app_router.dart';

final _mobileScaffoldKey = GlobalKey<ScaffoldState>();

class _MenuDestination {
  const _MenuDestination(this.label, this.path, this.icon,
      [this.color = SomiaColors.muted]);
  final String label;
  final String path;
  final IconData icon;
  final Color color;
}

const _menu = <_MenuDestination>[
  _MenuDestination(
      'Resumo', AppRoutes.dashboardPath, Icons.home_outlined, SomiaColors.blue),
  _MenuDestination('Receitas', AppRoutes.incomePath,
      Icons.arrow_circle_up_outlined, SomiaColors.green),
  _MenuDestination('Despesas', AppRoutes.expensesPath,
      Icons.arrow_circle_down_outlined, SomiaColors.red),
  _MenuDestination('Transferências', AppRoutes.transfersPath, Icons.swap_horiz),
  _MenuDestination(
      'Contas', AppRoutes.accountsPath, Icons.account_balance_wallet_outlined),
  _MenuDestination('Categorias', AppRoutes.categoriesPath, Icons.sell_outlined),
  _MenuDestination(
      'Configurações', AppRoutes.settingsPath, Icons.settings_outlined),
];

/// O drawer pertence ao Scaffold externo; este botão o abre a partir das páginas.
Widget? somiaMenuLeading(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 800 ? const SomiaMenuButton() : null;

class SomiaMenuButton extends StatelessWidget {
  const SomiaMenuButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: 'Abrir menu',
      icon: const Icon(Icons.menu),
      onPressed: () => _mobileScaffoldKey.currentState?.openDrawer());
}

class SomiaShell extends StatelessWidget {
  const SomiaShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return Scaffold(
              body: Row(children: [
            SizedBox(
                width: constraints.maxWidth < 1060 ? 78 : 228,
                child: _SomiaMenu(
                    location: location, compact: constraints.maxWidth < 1060)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ]));
        }
        return Scaffold(
            key: _mobileScaffoldKey,
            drawer: Drawer(
                width: math.min(300, constraints.maxWidth * 0.82),
                child: _SomiaMenu(location: location, isDrawer: true)),
            body: child);
      });
}

class _SomiaMenu extends StatelessWidget {
  const _SomiaMenu(
      {required this.location, this.isDrawer = false, this.compact = false});
  final String location;
  final bool isDrawer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: SomiaColors.sidebar,
        child: SafeArea(
            child: ListView(
          padding:
              EdgeInsets.fromLTRB(compact ? 10 : 14, 18, compact ? 10 : 14, 16),
          children: [
            Padding(
                padding: EdgeInsets.fromLTRB(compact ? 8 : 14, 20, 8, 32),
                child: Row(children: [
                  const Icon(Icons.spa_rounded,
                      color: SomiaColors.blue, size: 28),
                  if (!compact) ...[
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text('Somia',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold))),
                  ],
                  if (isDrawer)
                    IconButton(
                        tooltip: 'Fechar menu',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop()),
                ])),
            for (final destination in _menu)
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    key: ValueKey('menu-${destination.path}'),
                    leading: Icon(destination.icon, color: destination.color),
                    title: compact ? null : Text(destination.label),
                    minLeadingWidth: 0,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: compact ? 13 : 14),
                    selected: location == destination.path,
                    selectedTileColor: SomiaColors.surfaceHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      final router = GoRouter.of(context);
                      if (isDrawer) Navigator.of(context).pop();
                      if (location != destination.path) {
                        router.go(destination.path);
                      }
                    },
                  )),
          ],
        )));
  }
}

class SomiaQuickActions extends StatelessWidget {
  const SomiaQuickActions({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'Adicionar lançamento ou transferência',
        icon: const Icon(Icons.add),
        iconColor: Theme.of(context).colorScheme.onPrimary,
        style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            minimumSize: const Size(56, 56)),
        onSelected: (action) {
          if (action == 'transfer') {
            context.go('${AppRoutes.transfersPath}?create=1');
          } else {
            final path = action == 'income'
                ? AppRoutes.incomePath
                : AppRoutes.expensesPath;
            context.go('$path?create=1');
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
              value: 'income',
              child: ListTile(
                  leading: Icon(Icons.south_west), title: Text('Receita'))),
          PopupMenuItem(
              value: 'expense',
              child: ListTile(
                  leading: Icon(Icons.north_east), title: Text('Despesa'))),
          PopupMenuItem(
              value: 'transfer',
              child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Transferência'))),
        ],
      );
}
