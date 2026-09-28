/// Conversão exata de texto digitado para unidades mínimas (duas casas).
abstract final class MoneyMinor {
  static int parse(String input) {
    final value = input.trim();
    if (!RegExp(r'^-?\d+(?:[,.]\d{1,2})?$').hasMatch(value)) {
      throw const FormatException('Informe um valor com até duas casas decimais.');
    }
    final negative = value.startsWith('-');
    final parts = (negative ? value.substring(1) : value)
        .replaceAll(',', '.')
        .split('.');
    final whole = int.parse(parts[0]);
    final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
    if (whole > 90000000000000) {
      throw const FormatException('Valor acima do limite permitido.');
    }
    final amount = whole * 100 + cents;
    return negative ? -amount : amount;
  }

  static String plain(int minor) {
    final positive = minor.abs();
    final sign = minor < 0 ? '-' : '';
    return '$sign${positive ~/ 100},${(positive % 100).toString().padLeft(2, '0')}';
  }

  static String display(int minor, String currencyCode) {
    final prefix = currencyCode == 'BRL' ? 'R\$' : currencyCode;
    return '$prefix ${plain(minor)}';
  }
}
