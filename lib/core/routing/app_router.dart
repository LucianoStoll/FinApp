import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';

abstract final class AppRoutes {
  static const dashboard = 'dashboard';
  static const dashboardPath = '/';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboardPath,
  routes: [
    GoRoute(
      path: AppRoutes.dashboardPath,
      name: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),
  ],
);
