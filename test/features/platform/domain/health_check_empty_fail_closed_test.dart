import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/domain/backup.dart';

// Regression PLAT-hunt-20260914 PLAT-BUG-01 (Medium): HealthCheck.allPassed
// memakai Iterable.every yang bernilai true secara vacuous pada koleksi kosong,
// sehingga health check yang BELUM dijalankan dilaporkan "sehat". Kontrak
// fail-closed: tanpa satu pun pemeriksaan, allPassed wajib false.
void main() {
  group('HealthCheck fail-closed (PLAT-BUG-01)', () {
    test('checks kosong TIDAK dianggap semua lulus', () {
      const h = HealthCheck(id: 'h1', checks: {});
      expect(h.allPassed, isFalse);
    });

    test('semua checks true lulus', () {
      const h = HealthCheck(id: 'h2', checks: {'storage': true, 'db': true});
      expect(h.allPassed, isTrue);
    });

    test('satu checks false gagal (kontrak lama)', () {
      const h = HealthCheck(id: 'h3', checks: {'storage': true, 'db': false});
      expect(h.allPassed, isFalse);
    });
  });
}
