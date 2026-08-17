import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/payment_provider.dart';

void main() {
  group('PaymentProvider', () {
    test('InMemoryPaymentProvider creates a session', () async {
      final provider = InMemoryPaymentProvider();
      final session = await provider.createPayment(
        const PaymentRequest(amount: 10.0, currency: 'USD', creatorId: 'c1'),
      );
      expect(session.status, 'created');
      expect(session.sessionId, isNotEmpty);
      expect(session.paymentUrl, contains('c1'));
    });
  });
}
