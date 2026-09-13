// vs-hunt-20260914-platform PLAT-BUG-06 (Low): MemoryBaseline.utilization
// membagi dengan budgetMb tanpa penjaga, sehingga budget non-positif
// menghasilkan NaN/Infinity yang bisa merambat ke laporan dan UI.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/performance.dart';

void main() {
  group('MemoryBaseline.utilization (PLAT-BUG-06)', () {
    test('budgetMb nol menghasilkan 0.0, bukan NaN', () {
      const m = MemoryBaseline(baselineMb: 0, budgetMb: 0);
      expect(m.utilization, 0.0);
      expect(m.utilization.isNaN, isFalse);
    });

    test('baseline positif dengan budgetMb nol tetap berhingga', () {
      const m = MemoryBaseline(baselineMb: 480, budgetMb: 0);
      expect(m.utilization.isFinite, isTrue);
      expect(m.utilization, 0.0);
    });

    test('budgetMb negatif tidak menghasilkan rasio negatif', () {
      const m = MemoryBaseline(baselineMb: 480, budgetMb: -100);
      expect(m.utilization.isFinite, isTrue);
      expect(m.utilization, 0.0);
    });

    test('kontrak lama: budget positif tetap membagi normal', () {
      const m = MemoryBaseline(baselineMb: 480, budgetMb: 600);
      expect(m.utilization, 0.8);
    });

    test('kontrak lama: withinBudget tidak berubah oleh penjaga', () {
      const over = MemoryBaseline(baselineMb: 640, budgetMb: 600);
      expect(over.withinBudget, isFalse);
      expect(over.utilization, closeTo(1.0667, 0.0001));
      const zeroBudget = MemoryBaseline(baselineMb: 640, budgetMb: 0);
      expect(zeroBudget.withinBudget, isFalse);
    });
  });
}
