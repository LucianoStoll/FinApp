import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'schema_v1.dart';

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
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          for (final statement in schemaV1) {
            await m.issueCustomQuery(statement);
          }
        },
        onUpgrade: (m, from, to) async {
          if (from > to) {
            throw StateError('Banco v$from é mais novo que o aplicativo v$to');
          }
          // Cada nova versão deve acrescentar um case, sem editar schemaV1.
          // Drift atualiza user_version somente após a migration bem-sucedida.
          for (var version = from + 1; version <= to; version++) {
            switch (version) {
              default:
                throw StateError('Migration v$version não implementada');
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
