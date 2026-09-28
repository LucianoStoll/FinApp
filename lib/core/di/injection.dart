import 'package:get_it/get_it.dart';

import '../config/app_environment.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies(AppEnvironment environment) async {
  if (getIt.isRegistered<AppEnvironment>()) {
    await getIt.reset();
  }

  getIt.registerSingleton<AppEnvironment>(environment);

  // As dependências de cada feature serão registradas aqui por módulo.
  // Ex.: registerAccountsDependencies(getIt), registerTransactionsDependencies(getIt).
}
