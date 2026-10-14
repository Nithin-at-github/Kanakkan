import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionEntity copyWith tests', () {
    test('copyWith preserves lendPersonId when not specified', () {
      const tx = TransactionEntity(
        id: 1,
        type: 'expense',
        amount: 500,
        timestamp: 123456789,
        lendPersonId: 42,
      );

      final updated = tx.copyWith(note: 'Updated note');
      expect(updated.lendPersonId, equals(42));
      expect(updated.note, equals('Updated note'));
    });

    test('copyWith clears lendPersonId when clearLendPerson is true', () {
      const tx = TransactionEntity(
        id: 1,
        type: 'expense',
        amount: 500,
        timestamp: 123456789,
        lendPersonId: 42,
      );

      final unlinked = tx.copyWith(clearLendPerson: true);
      expect(unlinked.lendPersonId, isNull);
    });

    test('copyWith updates lendPersonId when provided', () {
      const tx = TransactionEntity(
        id: 1,
        type: 'expense',
        amount: 500,
        timestamp: 123456789,
        lendPersonId: 42,
      );

      final updated = tx.copyWith(lendPersonId: 99);
      expect(updated.lendPersonId, equals(99));
    });
  });
}

