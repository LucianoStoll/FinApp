import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'app_database.dart';

/// Exporta um snapshot consistente sem fechar o banco em uso. A importação
/// é preparada e aplicada apenas na próxima abertura do aplicativo.
abstract final class BackupService {
  static const _databaseName = 'finapp.sqlite';
  static const _pendingName = 'finapp.restore.pending';
  static const _previousName = 'finapp.before-restore.sqlite';

  static Future<Uint8List> export(AppDatabase database, Directory directory) async {
    await directory.create(recursive: true);
    final snapshot = File(p.join(directory.path, 'finapp.export.tmp.sqlite'));
    if (await snapshot.exists()) await snapshot.delete();
    try {
      // SQLite cria uma cópia consistente mesmo se houver WAL ativo.
      await database.customStatement('VACUUM INTO ?', [snapshot.path]);
      return await snapshot.readAsBytes();
    } finally {
      if (await snapshot.exists()) await snapshot.delete();
    }
  }

  static Future<void> stageRestore(Uint8List bytes, Directory directory) async {
    if (bytes.length < 100 ||
        String.fromCharCodes(bytes.take(15)) != 'SQLite format 3') {
      throw const FormatException('O arquivo não é um banco SQLite válido.');
    }
    final schemaVersion = ByteData.sublistView(bytes).getUint32(60, Endian.big);
    if (schemaVersion < 1 || schemaVersion > 5) {
      throw const FormatException('Versão do backup incompatível com este aplicativo.');
    }
    await directory.create(recursive: true);
    final candidate = File(p.join(directory.path, 'finapp.restore.check.sqlite'));
    if (await candidate.exists()) await candidate.delete();
    try {
      await candidate.writeAsBytes(bytes, flush: true);
      await _validate(candidate);
      final pending = File(p.join(directory.path, _pendingName));
      if (await pending.exists()) await pending.delete();
      await candidate.rename(pending.path);
    } finally {
      if (await candidate.exists()) await candidate.delete();
    }
  }

  static Future<void> _validate(File file) async {
    final database = AppDatabase(NativeDatabase(file));
    try {
      final integrity = await database.customSelect('PRAGMA integrity_check').get();
      if (integrity.length != 1 || integrity.single.read<String>('integrity_check') != 'ok') {
        throw const FormatException('O backup está corrompido.');
      }
      final violations = await database.customSelect('PRAGMA foreign_key_check').get();
      if (violations.isNotEmpty) {
        throw const FormatException('O backup contém vínculos inválidos.');
      }
      final tables = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      if (!names.containsAll(['accounts', 'categories', 'transactions', 'transfers'])) {
        throw const FormatException('O arquivo não contém os dados do Somia.');
      }
    } finally {
      await database.close();
    }
  }

  static Future<void> applyPendingRestore(Directory directory) async {
    final pending = File(p.join(directory.path, _pendingName));
    if (!await pending.exists()) return;
    await _validate(pending);
    final current = File(p.join(directory.path, _databaseName));
    final previous = File(p.join(directory.path, _previousName));

    // Recupera uma interrupção entre mover a base atual e instalar a nova.
    if (!await current.exists() && await previous.exists()) {
      await previous.rename(current.path);
      for (final suffix in ['-wal', '-shm']) {
        final oldSidecar = File('${previous.path}$suffix');
        if (await oldSidecar.exists()) {
          await oldSidecar.rename('${current.path}$suffix');
        }
      }
    }
    for (final suffix in ['', '-wal', '-shm']) {
      final old = File('${previous.path}$suffix');
      if (await old.exists()) await old.delete();
    }
    var movedCurrent = false;
    try {
      if (await current.exists()) {
        await current.rename(previous.path);
        movedCurrent = true;
      }
      for (final suffix in ['-wal', '-shm']) {
        final sidecar = File('${current.path}$suffix');
        if (await sidecar.exists()) {
          await sidecar.rename('${previous.path}$suffix');
        }
      }
      await pending.rename(current.path);
    } catch (_) {
      if (movedCurrent && !await current.exists()) {
        await previous.rename(current.path);
      }
      for (final suffix in ['-wal', '-shm']) {
        final oldSidecar = File('${previous.path}$suffix');
        if (await oldSidecar.exists()) {
          await oldSidecar.rename('${current.path}$suffix');
        }
      }
      rethrow;
    }
  }
}
