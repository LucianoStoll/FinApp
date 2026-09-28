import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'schema_v1.dart';
import 'schema_v2.dart';

/// Banco local do MVP. As migrations SQL ficam estáveis por versão; as DAOs
/// tipadas serão adicionadas pelas features sem alterar o schema publicado.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(
        LazyDatabase(() async {
          final directory = await getApplicationSupportDirectory();
          await directory.create(recursive: true);
          final file = File(p.join(directory.path, 'finapp.sqlite'));
          return NativeDatabase.createInBackground(file);
        }),
      );

  @override
  int get schemaVersion => 2;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {
          for (final statement in [...schemaV1, ...schemaV2]) {
            await customStatement(statement);
          }
        },
        onUpgrade: (m, from, to) async {
          for (var version = from + 1; version <= to; version++) {
            if (version != 2) {
              throw StateError('Migration v$version não implementada');
            }
            for (final statement in schemaV2) {
              await customStatement(statement);
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated || details.hadUpgrade) {
            final violations = await customSelect('PRAGMA foreign_key_check').get();
            if (violations.isNotEmpty) {
              throw StateError('Integridade referencial inválida após migration');
            }
          }
        },
      );
}
