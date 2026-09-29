import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/accounts/presentation/accounts_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';

abstract final class AppRoutes {
  static const dashboard = 'dashboard';
  static const dashboardPath = '/';
  static const accounts = 'accounts';
  static const accountsPath = '/accounts';
  static const categories = 'categories';
  static const categoriesPath = '/categories';
  static const transactions = 'transactions';
  static const transactionsPath = '/transactions';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboardPath,
  routes: [
    GoRoute(
      path: AppRoutes.transactionsPath,
      name: AppRoutes.transactions,
      builder: (context, state) => const TransactionsPage(),
    ),
    GoRoute(
      path: AppRoutes.categoriesPath,
      name: AppRoutes.categories,
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: AppRoutes.accountsPath,
      name: AppRoutes.accounts,
      builder: (context, state) => const AccountsPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboardPath,
      name: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),
  ],
);
