import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Somia', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const Card(child: ListTile(title: Text('Seus dados'),
          subtitle: Text('As informações ficam armazenadas neste dispositivo.'))),
        Card(child: ListTile(leading: const Icon(Icons.category_outlined),
          title: const Text('Categorias e subcategorias'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(AppRoutes.categories))),
        Card(child: ListTile(leading: const Icon(Icons.swap_horiz),
          title: const Text('Transferências'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(AppRoutes.transfers))),
      ]))),
  );
}
