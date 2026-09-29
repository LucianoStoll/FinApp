import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinApp'),
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 56),
                SizedBox(height: 16),
                Text(
                  'Fundação do FinApp pronta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'v0.1.0-alpha · offline-first',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                _AccountsButton(),
                SizedBox(height: 8),
                _CategoriesButton(),
                SizedBox(height: 8),
                _TransactionsButton(),
                SizedBox(height: 8),
                _TransfersButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountsButton extends StatelessWidget {
  const _AccountsButton();

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: () => context.goNamed(AppRoutes.accounts),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Minhas contas'),
      );
}

class _CategoriesButton extends StatelessWidget {
  const _CategoriesButton();

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => context.goNamed(AppRoutes.categories),
        icon: const Icon(Icons.category_outlined),
        label: const Text('Categorias'),
      );
}

class _TransactionsButton extends StatelessWidget {
  const _TransactionsButton();

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => context.goNamed(AppRoutes.transactions),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Receitas e despesas'),
      );
}

class _TransfersButton extends StatelessWidget {
  const _TransfersButton();

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => context.goNamed(AppRoutes.transfers),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Transferências'),
      );
}
