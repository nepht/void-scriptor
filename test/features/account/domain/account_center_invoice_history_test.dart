import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart'
    show TaxStatus;
import 'package:void_scriptor/features/account/domain/account_center_invoice_history.dart';
import '../../../canonical_source_support.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

void main() {
  group('AccountCenterInvoiceHistory', () {
    test('manifest preserves every canonical 115.37 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_invoices_receipts_billing_history.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.37');
      expect(manifest['acceptance'], <String>[
        'invoice_list',
        'receipt',
        'payment_status',
        'tax_info',
        'download',
        'refund_path',
        'dispute_path',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_invoice_history.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_invoice_history_test.dart',
      );
    });

    test('acceptance list is pinned to canonical sprint 115.37', () {
      if (skipUnlessExternalCanonical(
        "acceptance list is pinned to canonical sprint 115.37",
      )) {
        return;
      }
      final file = File(AccountCenterInvoiceHistory.canonicalSprintPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.37');

      expect(step['title'], 'Invoices, Receipts & Billing History');
      expect(
        step['acceptance'],
        AccountCenterInvoiceHistory.canonicalAcceptance,
      );
      expect(
        AccountCenterInvoiceHistory.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('product-spec billing rules still require refund terms up front', () {
      if (skipUnlessExternalCanonical(
        "product-spec billing rules still require refund terms up front",
      )) {
        return;
      }
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final billing = spec['billing_contract'] as Map<String, Object?>;

      expect(
        billing['status'],
        AccountCenterInvoiceHistory.billingContractStatus,
      );
      expect(billing['separation'], contains('invoice'));
      expect(
        billing['rules'],
        contains(
          'Show currency, tax, renewal, cancellation, and refund terms before '
          'confirmation.',
        ),
      );
      final securityContract =
          spec['security_contract'] as Map<String, Object?>;
      expect(
        securityContract['secrets'],
        contains('reauth_before_sensitive_action'),
      );
    });

    test('invoice list is newest-first, unique, and immutable', () {
      final history = AccountCenterInvoiceHistory('usd', _systemUtc, _allow)
        ..register(_invoice(id: 'inv-b', issuedAt: _utc(2026, 2, 1)))
        ..register(_invoice(id: 'inv-a', issuedAt: _utc(2026, 3, 1)))
        ..register(_invoice(id: 'inv-c', issuedAt: _utc(2026, 1, 1)));

      expect(
        history.invoices.map((invoice) => invoice.invoiceId).toList(),
        <String>['inv-a', 'inv-b', 'inv-c'],
      );
      expect(
        () => history.invoices.add(_invoice(id: 'inv-d')),
        throwsUnsupportedError,
      );

      expect(() => history.register(_invoice(id: 'inv-a')), throwsStateError);
      expect(() => history.register(_invoice(id: '   ')), throwsArgumentError);
    });

    test('invoice total reconciles subtotal plus tax in minor units', () {
      final invoice = _invoice(
        id: 'inv-tax',
        items: <InvoiceLineItem>[
          InvoiceLineItem(
            description: 'Pro seats',
            quantity: 2,
            unitAmount: 9.99,
            currency: 'usd',
          ),
          InvoiceLineItem(
            description: 'Storage add-on',
            quantity: 1,
            unitAmount: 10.00,
            currency: 'usd',
          ),
        ],
        tax: TaxStatus.applies,
        total: 31.58,
      );

      expect(invoice.subtotal, 29.98);
      expect(invoice.taxAmount, 1.60);
      expect(invoice.total, 31.58);
      expect(invoice.taxLine!.rate, 5.333333333333333);
      expect(invoice.taxLine!.regionCode, 'ID');

      // A stated total that does not reconcile is a data defect, not a
      // rounding surprise.
      expect(
        () => _invoice(
          id: 'inv-bad',
          items: <InvoiceLineItem>[
            InvoiceLineItem(
              description: 'Pro seats',
              quantity: 1,
              unitAmount: 10,
              currency: 'usd',
            ),
          ],
          total: 10.01,
        ),
        throwsArgumentError,
      );

      // A foreign currency never silently joins the account ledger.
      expect(
        () => _invoice(
          id: 'inv-eur',
          items: <InvoiceLineItem>[
            InvoiceLineItem(
              description: 'Pro seats',
              quantity: 1,
              unitAmount: 10,
              currency: 'eur',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test(
      'tax info is explicit: applies needs a line, unavailable needs none',
      () {
        final applied = _invoice(id: 'inv-1', tax: TaxStatus.applies);
        expect(applied.taxLine, isNotNull);
        expect(applied.taxAmount, greaterThan(0));

        final exempt = _invoice(id: 'inv-2', tax: TaxStatus.doesNotApply);
        expect(exempt.taxLine, isNull);
        expect(exempt.taxAmount, 0);

        final unknown = _invoice(
          id: 'inv-3',
          tax: TaxStatus.unavailable,
          items: <InvoiceLineItem>[_line(amount: 10)],
        );
        expect(unknown.taxLine, isNull);
        expect(unknown.taxAmount, 0);
        expect(unknown.taxInformation, 'unavailable');

        // Fabricating a zero-rate tax line for an unknown jurisdiction is
        // exactly the false precision this contract forbids.
        expect(
          () => _invoice(
            id: 'inv-4',
            tax: TaxStatus.unavailable,
            items: <InvoiceLineItem>[_line(amount: 10)],
            taxLine: InvoiceTaxLine(label: 'VAT', rate: 0, regionCode: 'ID'),
          ),
          throwsArgumentError,
        );
        expect(
          () => _invoice(
            id: 'inv-5',
            tax: TaxStatus.applies,
            items: <InvoiceLineItem>[_line(amount: 10)],
            withTaxLine: false,
          ),
          throwsArgumentError,
        );
      },
    );

    test('payment status is explicit and never a fabricated zero', () {
      final unpaid = InvoicePayment(state: InvoicePaymentState.unpaid);
      expect(unpaid.paidAmount, isNull);
      expect(unpaid.paidAt, isNull);

      final paid = InvoicePayment(
        state: InvoicePaymentState.paid,
        paidAmount: 29.98,
        paidAt: _utc(2026, 3, 2),
        methodLabel: 'VISA •••• 4242',
      );
      expect(paid.paidAt!.isUtc, isTrue);
      expect(paid.methodLabel, 'VISA •••• 4242');

      expect(
        () => InvoicePayment(state: InvoicePaymentState.paid, paidAmount: 10),
        throwsArgumentError,
      );
      expect(
        () => InvoicePayment(
          state: InvoicePaymentState.partiallyPaid,
          paidAmount: 0,
          paidAt: _utc(2026, 3, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => InvoicePayment(
          state: InvoicePaymentState.refunded,
          paidAt: _utc(2026, 3, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => InvoicePayment(
          state: InvoicePaymentState.disputed,
          paidAt: _utc(2026, 3, 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => InvoicePayment(
          state: InvoicePaymentState.unpaid,
          paidAt: _utc(2026, 3, 2),
        ),
        throwsArgumentError,
      );

      // A card number can never reach an invoice reference.
      expect(
        () => InvoicePayment(
          state: InvoicePaymentState.paid,
          paidAmount: 10,
          paidAt: _utc(2026, 3, 2),
          methodLabel: '4242424242424242',
        ),
        throwsA(isA<InvoiceCardDataRefused>()),
      );
    });

    test('receipt links to a real invoice and stays currency-consistent', () {
      final receipt = InvoiceReceipt(
        receiptId: 'rcp-1',
        invoiceId: 'inv-1',
        issuedAt: _utc(2026, 3, 2),
        amount: 29.98,
        currency: 'usd',
        methodLabel: 'VISA •••• 4242',
      );
      final history = AccountCenterInvoiceHistory('usd', _systemUtc, _allow)
        ..register(
          _invoice(
            id: 'inv-1',
            payment: InvoicePayment(
              state: InvoicePaymentState.paid,
              paidAmount: 29.98,
              paidAt: _utc(2026, 3, 2),
              methodLabel: 'VISA •••• 4242',
            ),
          ),
          receipt: receipt,
        );

      expect(history.receiptFor('inv-1')!.receiptId, 'rcp-1');
      expect(() => history.receiptFor('inv-unknown'), throwsStateError);

      // No receipt means explicitly unavailable, never a generated one.
      history.register(_invoice(id: 'inv-2'));
      expect(history.receiptFor('inv-2'), isNull);

      expect(
        () => history.register(
          _invoice(id: 'inv-3'),
          receipt: InvoiceReceipt(
            receiptId: 'rcp-2',
            invoiceId: 'inv-unknown',
            issuedAt: _utc(2026, 3, 2),
            amount: 10,
            currency: 'usd',
            methodLabel: 'VISA •••• 4242',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => history.register(
          _invoice(id: 'inv-4'),
          receipt: InvoiceReceipt(
            receiptId: 'rcp-3',
            invoiceId: 'inv-4',
            issuedAt: _utc(2026, 3, 2),
            amount: 10,
            currency: 'eur',
            methodLabel: 'VISA •••• 4242',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('download descriptor is explicit and carries no secret or path', () {
      final document = InvoiceDocument(
        format: InvoiceDocumentFormat.pdf,
        issuedAt: _utc(2026, 3, 2),
        byteSize: 48213,
      );
      final history = AccountCenterInvoiceHistory('usd', _systemUtc, _allow)
        ..register(_invoice(id: 'inv-pdf'), document: document)
        ..register(_invoice(id: 'inv-none'));

      final available = history.downloadDescriptor('inv-pdf');
      expect(available['available'], isTrue);
      expect(available['format'], 'pdf');
      expect(available['byte_size'], 48213);
      expect(available.keys, isNot(contains('path')));
      expect(jsonEncode(available), isNot(contains('C:')));
      expect(jsonEncode(available), isNot(contains('file://')));

      final missing = history.downloadDescriptor('inv-none');
      expect(missing['available'], isFalse);
      expect(missing['format'], isNull);
      expect(missing['byte_size'], isNull);
      expect(missing.keys, hasLength(1));

      expect(
        () => InvoiceDocument(
          format: InvoiceDocumentFormat.pdf,
          issuedAt: _utc(2026, 3, 2),
          byteSize: 0,
        ),
        throwsArgumentError,
      );
    });

    test('refund path is reauth-gated, bounded, and cumulative-safe', () async {
      final history = _paidHistory();

      final refund = await history.requestRefund(
        invoiceId: 'inv-1',
        amount: 9.99,
        reason: 'Duplicate charge for the cancelled seat.',
      );
      expect(refund.state, RefundState.requested);
      expect(refund.amount, 9.99);
      expect(refund.requestedAt, _utc(2026, 3, 3));
      expect(history.refundsFor('inv-1'), hasLength(1));

      // Reason is mandatory: an unexplained refund is a support dead end.
      await expectLater(
        () =>
            history.requestRefund(invoiceId: 'inv-1', amount: 1, reason: '   '),
        throwsArgumentError,
      );
      // Cumulative refunds can never exceed what was actually collected
      // (29.98): 9.99 leaves 19.99, and one cent more is refused.
      await history.requestRefund(
        invoiceId: 'inv-1',
        amount: 19.99,
        reason: 'Remaining balance after partial usage.',
      );
      await expectLater(
        () => history.requestRefund(
          invoiceId: 'inv-1',
          amount: 0.01,
          reason: 'Overflow attempt.',
        ),
        throwsStateError,
      );
      await expectLater(
        () => history.requestRefund(
          invoiceId: 'inv-1',
          amount: 0,
          reason: 'Zero refund.',
        ),
        throwsArgumentError,
      );
      await expectLater(
        () => history.requestRefund(
          invoiceId: 'inv-unpaid',
          amount: 5,
          reason: 'Never paid.',
        ),
        throwsStateError,
      );
      await expectLater(
        () => history.requestRefund(
          invoiceId: 'inv-unknown',
          amount: 5,
          reason: 'Unknown invoice.',
        ),
        throwsStateError,
      );

      await expectLater(
        () => history.fileDispute(
          invoiceId: 'inv-unknown',
          reason: 'Unknown invoice.',
        ),
        throwsStateError,
      );

      // Settling the full collected amount flips the payment status.
      refund.settle(_utc(2026, 3, 4));
      expect(refund.state, RefundState.settled);
      expect(refund.settledAt, _utc(2026, 3, 4));
      expect(
        history.paymentStatusFor('inv-1').state,
        InvoicePaymentState.partiallyRefunded,
      );
      // Settling the second request covers everything that was collected.
      history.refundsFor('inv-1')[1].settle(_utc(2026, 3, 4));
      expect(
        history.paymentStatusFor('inv-1').state,
        InvoicePaymentState.refunded,
      );
    });

    test('a denied reauthentication fails closed and is audited', () async {
      final history = _paidHistory(denyReauth: true);
      await expectLater(
        history.requestRefund(
          invoiceId: 'inv-1',
          amount: 5,
          reason: 'Should be refused.',
        ),
        throwsStateError,
      );
      await expectLater(
        history.fileDispute(invoiceId: 'inv-1', reason: 'Should be refused.'),
        throwsStateError,
      );
      expect(history.refundsFor('inv-1'), isEmpty);
      expect(history.disputeFor('inv-1'), isNull);
      expect(
        history.audit.map((event) => event.action).toList(),
        containsAll(<String>['denied_request_refund', 'denied_file_dispute']),
      );
    });

    test(
      'dispute path enforces the declared window and one open dispute',
      () async {
        final history = _paidHistory();
        final dispute = await history.fileDispute(
          invoiceId: 'inv-1',
          reason: 'Service was never provisioned for the billed month.',
          evidence: <DisputeEvidence>[
            DisputeEvidence(
              evidenceId: 'ev-1',
              kind: DisputeEvidenceKind.correspondence,
              sha256: 'a' * 64,
              addedAt: _utc(2026, 3, 3),
            ),
          ],
        );
        expect(dispute.disputeId, startsWith('dsp-'));
        expect(dispute.state, DisputeState.filed);
        expect(dispute.evidence, hasLength(1));
        expect(
          () => dispute.evidence.add(_evidence('ev-2')),
          throwsUnsupportedError,
        );

        await expectLater(
          () => history.fileDispute(
            invoiceId: 'inv-1',
            reason: 'Second dispute while one is open.',
          ),
          throwsStateError,
        );
        await expectLater(
          () => history.fileDispute(
            invoiceId: 'inv-unpaid',
            reason: 'Unpaid invoice cannot be disputed.',
          ),
          throwsStateError,
        );

        dispute.resolve(DisputeState.won, _utc(2026, 3, 9));
        expect(dispute.state, DisputeState.won);
        expect(dispute.resolvedAt, _utc(2026, 3, 9));
        expect(
          () => dispute.resolve(DisputeState.filed, _utc(2026, 3, 9)),
          throwsStateError,
        );

        // After the window closes the provider accepts no new dispute; the
        // contract never invents an open-ended one.
        final closed = _paidHistory(now: _utc(2026, 4, 2));
        await expectLater(
          closed.fileDispute(invoiceId: 'inv-1', reason: 'Too late.'),
          throwsStateError,
        );

        // An invoice whose provider declared no dispute window is closed too.
        final noWindow = _paidHistory(
          now: _utc(2026, 3, 3),
          withDisputeDeadline: false,
        );
        await expectLater(
          noWindow.fileDispute(invoiceId: 'inv-1', reason: 'No window.'),
          throwsStateError,
        );

        expect(
          () => DisputeEvidence(
            evidenceId: 'ev-3',
            kind: DisputeEvidenceKind.correspondence,
            sha256: 'not-a-digest',
            addedAt: _utc(2026, 3, 3),
          ),
          throwsArgumentError,
        );
      },
    );

    test('public serialization never leaks a card number or token', () {
      final history = _paidHistory();
      final json = jsonEncode(history.toPublicJson());
      expect(json, isNot(contains('4242424242424242')));
      expect(json, isNot(contains('provider_token')));
      expect(json, isNot(contains('pm_tok')));
      expect(history.toPublicJson()['refundable_remaining'], 29.98);

      for (final event in history.audit) {
        expect(event.toJson().keys, isNot(contains('method_label')));
      }
    });
  });
}

Future<bool> _allow() async => true;

DateTime _systemUtc() => DateTime.now().toUtc();

DateTime _utc(int year, int month, int day) => DateTime.utc(year, month, day);

InvoiceLineItem _line({
  String description = 'Pro seats',
  double amount = 29.98,
}) => InvoiceLineItem(
  description: description,
  quantity: 1,
  unitAmount: amount,
  currency: 'usd',
);

InvoiceTaxLine? _taxLine() =>
    InvoiceTaxLine(label: 'VAT', rate: 5.333333333333333, regionCode: 'ID');

Invoice _invoice({
  required String id,
  DateTime? issuedAt,
  List<InvoiceLineItem>? items,
  TaxStatus tax = TaxStatus.unavailable,
  InvoiceTaxLine? taxLine,
  bool withTaxLine = true,
  double? total,
  InvoicePayment? payment,
  DateTime? disputeDeadline,
  bool withDisputeDeadline = true,
}) {
  final lines = items ?? <InvoiceLineItem>[_line()];
  final subtotalMinor = lines.fold<int>(
    0,
    (sum, line) => sum + line.lineTotalMinor,
  );
  final resolvedLine = tax == TaxStatus.applies
      ? (withTaxLine ? (taxLine ?? _taxLine()) : null)
      : taxLine;
  final taxMinor = resolvedLine == null
      ? 0
      : ((subtotalMinor * resolvedLine.rate) / 100).round();
  return Invoice(
    invoiceId: id,
    number: 'VS-${id.toUpperCase()}',
    issuedAt: issuedAt ?? _utc(2026, 3, 1),
    currency: 'usd',
    lineItems: lines,
    tax: tax,
    taxLine: resolvedLine,
    total: total ?? (subtotalMinor + taxMinor) / 100,
    status: InvoiceStatus.open,
    payment: payment ?? InvoicePayment(state: InvoicePaymentState.unpaid),
    disputeDeadline: withDisputeDeadline
        ? (disputeDeadline ?? _utc(2026, 3, 31))
        : null,
  );
}

DisputeEvidence _evidence(String id) => DisputeEvidence(
  evidenceId: id,
  kind: DisputeEvidenceKind.correspondence,
  sha256: 'b' * 64,
  addedAt: _utc(2026, 3, 3),
);

AccountCenterInvoiceHistory _paidHistory({
  bool denyReauth = false,
  DateTime? now,
  DateTime? disputeDeadline,
  bool withDisputeDeadline = true,
}) {
  final at = now ?? _utc(2026, 3, 3);
  return AccountCenterInvoiceHistory('usd', () => at, () async => !denyReauth)
    ..register(
      _invoice(
        id: 'inv-1',
        payment: InvoicePayment(
          state: InvoicePaymentState.paid,
          paidAmount: 29.98,
          paidAt: _utc(2026, 3, 2),
          methodLabel: 'VISA •••• 4242',
        ),
        disputeDeadline: disputeDeadline,
        withDisputeDeadline: withDisputeDeadline,
      ),
    )
    ..register(
      _invoice(
        id: 'inv-unpaid',
        disputeDeadline: disputeDeadline,
        withDisputeDeadline: withDisputeDeadline,
      ),
    );
}
