import 'package:finapp/features/transfers/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = Transfer(
      id: 'x',
      sourceAccountId: 'a',
      sourceAccountName: 'A',
      destinationAccountId: 'b',
      destinationAccountName: 'B',
      currencyCode: 'BRL',
      amountMinor: 100,
      date: DateTime(2026, 9, 30),
      dueDate: DateTime(2026, 12, 31, 23, 59),
      effectiveDate: DateTime(2027, 1, 1),
      isEffective: false);
  test('período por vencimento inclui último dia e conta de origem ou destino',
      () {
    final filter = TransferFilter(
        from: DateTime(2026, 12), to: DateTime(2026, 12, 31), accountId: 'b');
    expect(filter.matches(item), isTrue);
    expect(TransferFilter(from: DateTime(2027, 1)).matches(item), isFalse);
    expect(const TransferFilter(accountId: 'c').matches(item), isFalse);
    expect(const TransferFilter(effective: true).matches(item), isFalse);
    expect(const TransferFilter(effective: false).matches(item), isTrue);
  });
  test('data de lançamento e efetivação são independentes do vencimento', () {
    expect(
        TransferFilter(
                from: DateTime(2026, 9),
                to: DateTime(2026, 9, 30),
                dateField: TransferDateField.posted)
            .matches(item),
        isTrue);
    expect(
        TransferFilter(
                from: DateTime(2027, 1), dateField: TransferDateField.effective)
            .matches(item),
        isTrue);
    expect(const TransferFilter().matches(item), isTrue);
  });
}
