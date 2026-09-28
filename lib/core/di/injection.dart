import 'package:get_it/get_it.dart';

import '../config/app_environment.dart';
import '../database/app_database.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies(AppEnvironment environment) async {
  if (getIt.isRegistered<AppEnvironment>()) {
    await getIt.reset();
  }

  getIt.registerSingleton<AppEnvironment>(environment);
  final database = AppDatabase.open();
  try {
    // Força a abertura e a criação/migration antes de exibir a interface.
    await database.customSelect('PRAGMA user_version').getSingle();
  } catch (_) {
    await database.close();
    rethrow;
  }
  getIt.registerSingleton<AppDatabase>(database, dispose: (db) => db.close());

  // As dependências de cada feature serão registradas aqui por módulo.
}
