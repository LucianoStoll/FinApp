import 'package:flutter/foundation.dart';

/// Período compartilhado pelas páginas durante a sessão do aplicativo.
class ReferenceMonth extends ValueNotifier<DateTime> {
  ReferenceMonth([DateTime? initial])
      : super(monthOnly(initial ?? DateTime.now()));

  static DateTime monthOnly(DateTime date) => DateTime(date.year, date.month);
  void select(DateTime date) => value = monthOnly(date);
  void move(int delta) => select(DateTime(value.year, value.month + delta));
}

final referenceMonth = ReferenceMonth();
