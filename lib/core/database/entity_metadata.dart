import 'package:uuid/uuid.dart';

/// IDs independentes do dispositivo e instantes UTC para os registros locais.
final class EntityMetadata {
  EntityMetadata._();

  static const _uuid = Uuid();

  static String newId() => _uuid.v4();

  /// Milissegundos desde Unix epoch; SQLite persiste como INTEGER.
  static int nowUtcMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;
}
