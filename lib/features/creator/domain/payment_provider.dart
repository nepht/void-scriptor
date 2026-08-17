/// Sprint 43 — Step 43.31 Funding Center, 43.32 Donation Integration, 43.33 Donation UI.
///
/// Payment provider abstraction; regional implementations can be plugged in
/// without binding the UI to a specific payment method.
class PaymentRequest {
  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.creatorId,
    this.projectId,
  });

  final double amount;
  final String currency;
  final String creatorId;
  final String? projectId;
}

class PaymentSession {
  const PaymentSession({
    required this.sessionId,
    required this.status,
    required this.paymentUrl,
  });

  final String sessionId;
  final String status;
  final String paymentUrl;
}

abstract class PaymentProvider {
  Future<PaymentSession> createPayment(PaymentRequest request);
}

/// Minimal in-memory provider for testing.
class InMemoryPaymentProvider implements PaymentProvider {
  @override
  Future<PaymentSession> createPayment(PaymentRequest request) async {
    return PaymentSession(
      sessionId: 'test-session-${request.creatorId}',
      status: 'created',
      paymentUrl: 'https://test.example.com/pay/${request.creatorId}',
    );
  }
}
