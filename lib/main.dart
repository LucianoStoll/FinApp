import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.fromDefine();
  await configureDependencies(environment);

  runApp(const FinApp());
}
