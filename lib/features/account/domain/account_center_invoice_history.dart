/// Sprint 115.37 — Invoices, Receipts & Billing History.
///
/// Local metadata-only invoice ledger. It models what a billing history has
/// to be able to say without contacting anybody: which invoices exist, what
/// each line item and tax treatment was, what the payment status actually
/// is, whether a receipt exists, whether a document can be downloaded, and
/// whether the user can request a refund or file a dispute.
///
/// Three product rules are enforced structurally rather than by
/// convention:
///
/// * A closed or unknown jurisdiction never becomes a zero. Tax state is
///   tri-state ([TaxStatus]) and an unavailable tax carries no rate.
/// * Refund and dispute are *requests*, not results. A payment is only
///   `refunded` when settled refund requests cover what was collected, and
///   only a provider would settle them — the process is injected.
/// * No document path and no card reference ever leaves this file. The
///   download surface is a descriptor (format + size), and a payment
///   reference must be masked.
///
/// Live billing, payment-provider refund/dispute execution, invoice document
/// generation, public-trust signing, hosted CI, telemetry, hardware,
/// adoption, and publication stay `DEFERRED-EXTERNAL`; the product-spec
/// billing contract remains
/// [AccountCenterInvoiceHistory.billingContractStatus].
library;

import 'dart:collection';

import 'package:void_scriptor/features/account/domain/account_center_billing_summary.dart'
    show TaxStatus;
import 'package:void_scriptor/features/account/domain/account_center_payment_methods.dart'
    show PaymentMethodInputError;

/// Re-exported so a caller that only imports this contract still sees the
/// "raw card data refused" signal when an invoice or receipt carries an
/// instrument reference.
typedef InvoiceCardDataRefused = PaymentMethodInputError;

/// Document state of the invoice itself. The paid/refunded verdict belongs
/// to [InvoicePayment], never here, so a document cannot be closed and
/// unpaid at the same time.
enum InvoiceStatus { open, closed, voided }

/// Payment verdict of an invoice.
///
/// [refunded], [partiallyRefunded], and [disputed] are *derived* states: they
/// are computed from settled refund requests and open disputes recorded by
/// [AccountCenterInvoiceHistory]. A provider snapshot therefore cannot
/// declare them — it has to declare what was paid, and the ledger derives
/// the consequence.
enum InvoicePaymentState {
  unpaid,
  pending,
  partiallyPaid,
  paid,
  failed,
  refunded,
  partiallyRefunded,
  disputed,
}

/// The states a payment descriptor may declare. The rest are derived.
const Set<InvoicePaymentState> _declaredPaymentStates = <InvoicePaymentState>{
  InvoicePaymentState.unpaid,
  InvoicePaymentState.pending,
  InvoicePaymentState.partiallyPaid,
  InvoicePaymentState.paid,
  InvoicePaymentState.failed,
};

/// What was actually collected for an invoice.
///
/// `paidAmount == null` means explicitly unavailable or "nothing collected",
/// never a fabricated zero. [methodLabel] is a masked display reference only.
final class InvoicePayment {
  InvoicePayment({
    required this.state,
    this.paidAmount,
    this.paidAt,
    String? methodLabel,
  }) : methodLabel = _methodLabel(methodLabel) {
    if (!_declaredPaymentStates.contains(state)) {
      throw ArgumentError.value(
        state,
        'state',
        '${state.name} is derived from the refund/dispute ledger and must '
            'not be declared by a payment snapshot.',
      );
    }
    _validateDeclared(state, paidAmount, paidAt);
  }

  /// Ledger-derived verdict. The declared-state guard above is exactly what
  /// stops a provider snapshot from asserting a refund that never happened,
  /// so the derivation path bypasses it deliberately and reuses the same
  /// amount/date invariants.
  InvoicePayment._derived({
    required this.state,
    required this.paidAmount,
    required this.paidAt,
    required this.methodLabel,
  });

  final InvoicePaymentState state;

  /// `null` means explicitly unavailable — never a fabricated zero.
  final double? paidAmount;
  final DateTime? paidAt;

  /// Masked instrument label, for example `VISA •••• 4242`.
  final String? methodLabel;

  static void _validateDeclared(
    InvoicePaymentState state,
    double? paidAmount,
    DateTime? paidAt,
  ) {
    if (state == InvoicePaymentState.unpaid ||
        state == InvoicePaymentState.pending) {
      if (paidAmount != null) {
        throw ArgumentError('An ${state.name} invoice has collected nothing.');
      }
      if (paidAt != null) {
        throw ArgumentError('An ${state.name} invoice has no payment date.');
      }
      return;
    }
    if (paidAmount == null) {
      throw ArgumentError('A ${state.name} invoice requires paidAmount.');
    }
    if (paidAt == null) {
      throw ArgumentError('A ${state.name} invoice requires paidAt.');
    }
    _requireUtc(paidAt, 'paidAt');
    if (!paidAmount.isFinite || paidAmount <= 0) {
      throw ArgumentError.value(
        paidAmount,
        'paidAmount',
        'Must be finite and greater than zero.',
      );
    }
  }
}

/// A single billable line. Line totals are computed in minor units so a
/// display total never leaks binary floating point noise.
final class InvoiceLineItem {
  InvoiceLineItem({
    required String description,
    required this.quantity,
    required this.unitAmount,
    required String currency,
  }) : description = _required(description, 'description'),
       currency = _currency(currency) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be at least 1.');
    }
    if (!unitAmount.isFinite || unitAmount < 0) {
      throw ArgumentError.value(
        unitAmount,
        'unitAmount',
        'Must be finite and >= 0.',
      );
    }
  }

  final String description;
  final int quantity;
  final double unitAmount;
  final String currency;

  int get lineTotalMinor => (unitAmount * 100 * quantity).round();
}

/// Stated tax treatment for a jurisdiction that is actually known.
final class InvoiceTaxLine {
  InvoiceTaxLine({
    required String label,
    required this.rate,
    required String regionCode,
  }) : label = _required(label, 'label'),
       regionCode = _required(regionCode, 'regionCode') {
    if (!rate.isFinite || rate < 0 || rate > 100) {
      throw ArgumentError.value(
        rate,
        'rate',
        'Must be finite and within 0..100.',
      );
    }
  }

  final String label;
  final double rate;
  final String regionCode;
}

/// A payment receipt. A receipt documents a settled charge; when none exists
/// the history reports it as unavailable rather than generating one.
final class InvoiceReceipt {
  InvoiceReceipt({
    required String receiptId,
    required String invoiceId,
    required this.issuedAt,
    required this.amount,
    required String currency,
    String? methodLabel,
  }) : receiptId = _required(receiptId, 'receiptId'),
       invoiceId = _required(invoiceId, 'invoiceId'),
       currency = _currency(currency),
       methodLabel = _methodLabel(methodLabel) {
    _requireUtc(issuedAt, 'issuedAt');
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be finite and greater than zero.',
      );
    }
  }

  final String receiptId;
  final String invoiceId;
  final DateTime issuedAt;
  final double amount;
  final String currency;
  final String? methodLabel;
}

/// Downloadable document formats. The bytes are produced by the billing
/// provider; this contract only records that they exist and how large they
/// are. It never stores or invents a file location.
enum InvoiceDocumentFormat { pdf, html, json }

/// Existence and size of a downloadable invoice document.
final class InvoiceDocument {
  InvoiceDocument({
    required this.format,
    required this.issuedAt,
    required this.byteSize,
  }) {
    _requireUtc(issuedAt, 'issuedAt');
    if (byteSize < 1) {
      throw ArgumentError.value(byteSize, 'byteSize', 'Must be at least 1.');
    }
  }

  final InvoiceDocumentFormat format;
  final DateTime issuedAt;
  final int byteSize;
}

/// One invoice with reconciled arithmetic.
final class Invoice {
  Invoice({
    required String invoiceId,
    required String number,
    required this.issuedAt,
    required String currency,
    required Iterable<InvoiceLineItem> lineItems,
    required this.tax,
    required this.taxLine,
    required this.total,
    this.status = InvoiceStatus.open,
    this.payment,
    this.disputeDeadline,
  }) : invoiceId = _required(invoiceId, 'invoiceId'),
       number = _required(number, 'number'),
       currency = _currency(currency),
       lineItems = List<InvoiceLineItem>.of(lineItems) {
    _requireUtc(issuedAt, 'issuedAt');
    if (this.lineItems.isEmpty) {
      throw ArgumentError('An invoice requires at least one line item.');
    }
    for (final item in this.lineItems) {
      if (item.currency != this.currency) {
        throw ArgumentError.value(
          item.description,
          'lineItems',
          'Currency must match the invoice currency.',
        );
      }
    }
    if (tax == TaxStatus.applies && taxLine == null) {
      throw ArgumentError('An invoice whose tax applies requires a taxLine.');
    }
    if (tax != TaxStatus.applies && taxLine != null) {
      throw ArgumentError(
        'Only an invoice whose tax applies may carry a taxLine; an '
        'unavailable jurisdiction must not be filled with a zero rate.',
      );
    }
    if (disputeDeadline != null) {
      _requireUtc(disputeDeadline!, 'disputeDeadline');
    }
    final reconciled = (subtotalMinor + (taxAmount * 100).round()) / 100;
    if ((reconciled * 100).round() != (total * 100).round()) {
      throw ArgumentError.value(
        total,
        'total',
        'Must equal subtotal plus tax (${reconciled.toStringAsFixed(2)}).',
      );
    }
  }

  final String invoiceId;
  final String number;
  final DateTime issuedAt;
  final String currency;
  final List<InvoiceLineItem> lineItems;
  final TaxStatus tax;
  final InvoiceTaxLine? taxLine;
  final InvoiceStatus status;

  /// `null` means no verdict is available yet — never a fabricated state.
  final InvoicePayment? payment;

  /// Last day a dispute can be filed. `null` means the provider declared no
  /// dispute window, which closes the path rather than opening it forever.
  final DateTime? disputeDeadline;
  final double total;

  int get subtotalMinor =>
      lineItems.fold<int>(0, (sum, item) => sum + item.lineTotalMinor);

  double get subtotal => subtotalMinor / 100;

  double get taxAmount {
    final line = taxLine;
    if (line == null) return 0;
    return ((subtotalMinor * line.rate) / 100).round() / 100;
  }

  /// Human-readable tax summary. `unavailable` is an explicit answer here,
  /// not a gap, because 115.49 formats this surface.
  String get taxInformation {
    final line = taxLine;
    if (line == null) {
      return switch (tax) {
        TaxStatus.doesNotApply => 'not_applicable',
        TaxStatus.applies => 'unavailable',
        TaxStatus.unavailable => 'unavailable',
      };
    }
    return '${line.label} ${line.rate.toStringAsFixed(2)}% (${line.regionCode})';
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'invoice_id': invoiceId,
    'number': number,
    'issued_at': issuedAt.toIso8601String(),
    'currency': currency,
    'status': status.name,
    'subtotal': subtotal,
    'tax_status': tax.name,
    'tax_information': taxInformation,
    'total': total,
    'payment_state': payment?.state.name,
    'paid_amount': payment?.paidAmount,
    'paid_at': payment?.paidAt?.toIso8601String(),
    'dispute_deadline': disputeDeadline?.toIso8601String(),
  };
}

/// Lifecycle of a refund request. Only a provider settles one; [RefundState.settled]
/// is therefore always an injected decision, never a local guess.
enum RefundState { requested, settled, rejected, cancelled }

/// A refund request bound to one invoice.
final class InvoiceRefund {
  InvoiceRefund._({
    required this.refundId,
    required this.invoiceId,
    required this.amount,
    required this.reason,
    required this.requestedAt,
  });

  final String refundId;
  final String invoiceId;
  final double amount;
  final String reason;
  final DateTime requestedAt;
  RefundState state = RefundState.requested;
  DateTime? settledAt;
  DateTime? resolvedAt;

  void settle(DateTime at) {
    _requireUtc(at, 'settledAt');
    _requireRequested('settled');
    state = RefundState.settled;
    settledAt = at;
    resolvedAt = at;
  }

  /// The provider declined this refund, so no money ever left the account.
  ///
  /// [RefundState.rejected] and [RefundState.cancelled] were reachable in the
  /// enum but nothing could produce them: `settle` was the only transition, so
  /// a declined request stayed `requested` forever and kept holding the
  /// invoice's refundable budget that it had never been given. Both verdicts
  /// are now reachable, and both leave `settledAt` null — a refusal returns
  /// the amount to [AccountCenterInvoiceHistory.refundableRemaining].
  void reject(DateTime at) {
    _requireUtc(at, 'resolvedAt');
    _requireRequested('rejected');
    state = RefundState.rejected;
    resolvedAt = at;
  }

  /// The user withdrew this refund before the provider decided it.
  void cancel(DateTime at) {
    _requireUtc(at, 'resolvedAt');
    _requireRequested('cancelled');
    state = RefundState.cancelled;
    resolvedAt = at;
  }

  /// A request can only reach a terminal verdict once, and only from
  /// `requested`. Re-settling a settled refund would double the amount the
  /// ledger considers collected back.
  void _requireRequested(String next) {
    if (state != RefundState.requested) {
      throw StateError('A ${state.name} refund cannot become $next.');
    }
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'refund_id': refundId,
    'invoice_id': invoiceId,
    'amount': amount,
    'reason': reason,
    'requested_at': requestedAt.toIso8601String(),
    'state': state.name,
    'settled_at': settledAt?.toIso8601String(),
  };
}

/// Kinds of evidence a dispute may cite. Only a digest is stored: the
/// document itself never enters the account metadata.
enum DisputeEvidenceKind { correspondence, receipt, providerNotice, other }

/// One piece of dispute evidence, stored as a SHA-256 digest.
final class DisputeEvidence {
  DisputeEvidence({
    required String evidenceId,
    required this.kind,
    required String sha256,
    required this.addedAt,
  }) : evidenceId = _required(evidenceId, 'evidenceId'),
       sha256 = _sha256(sha256) {
    _requireUtc(addedAt, 'addedAt');
  }

  final String evidenceId;
  final DisputeEvidenceKind kind;
  final String sha256;
  final DateTime addedAt;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'evidence_id': evidenceId,
    'kind': kind.name,
    'sha256': sha256,
    'added_at': addedAt.toIso8601String(),
  };
}

/// Dispute lifecycle. A dispute is filed against a paid invoice inside the
/// provider's declared window and holds a single terminal verdict.
enum DisputeState { filed, won, lost, withdrawn }

/// An open or settled dispute.
final class InvoiceDispute {
  InvoiceDispute._({
    required this.disputeId,
    required this.invoiceId,
    required this.reason,
    required this.filedAt,
    required Iterable<DisputeEvidence> evidence,
  }) : _evidence = List<DisputeEvidence>.of(evidence);

  final String disputeId;
  final String invoiceId;
  final String reason;
  final DateTime filedAt;
  final List<DisputeEvidence> _evidence;
  DisputeState state = DisputeState.filed;
  DateTime? resolvedAt;

  List<DisputeEvidence> get evidence => UnmodifiableListView(_evidence);

  bool get isOpen => state == DisputeState.filed;

  void resolve(DisputeState next, DateTime at) {
    _requireUtc(at, 'resolvedAt');
    if (!isOpen) {
      throw StateError('A ${state.name} dispute is already resolved.');
    }
    if (next == DisputeState.filed) {
      throw ArgumentError.value(
        next,
        'state',
        'Resolve needs a terminal verdict.',
      );
    }
    state = next;
    resolvedAt = at;
  }

  List<DisputeEvidence> get immutableEvidence => evidence;
}

/// Audit record. A billing audit event never carries an amount that could
/// be a card reference, a document path, or a provider token.
final class InvoiceAuditEvent {
  const InvoiceAuditEvent({
    required this.action,
    required this.invoiceId,
    required this.at,
  });

  final String action;
  final String invoiceId;
  final DateTime at;

  Map<String, Object?> toJson() => <String, Object?>{
    'action': action,
    'invoice_id': invoiceId,
    'at': at.toIso8601String(),
  };
}

typedef InvoiceClock = DateTime Function();
typedef InvoiceReauthentication = Future<bool> Function();

/// Account-scoped invoice and billing history.
final class AccountCenterInvoiceHistory {
  /// Product-spec `billing_contract.status` — this step never claims a live
  /// billing or dispute integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  static const canonicalAcceptance = <String>[
    'invoice_list',
    'receipt',
    'payment_status',
    'tax_info',
    'download',
    'refund_path',
    'dispute_path',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// When no reauthentication callback is supplied, refunds and disputes
  /// fail closed: a missing broker is not a granted one.
  ///
  /// The clock and the reauthentication broker are optional positional
  /// arguments so production can pass a live broker while a test injects a
  /// fixed clock; omitting the broker fails closed.
  AccountCenterInvoiceHistory(
    String accountCurrency, [
    this._now = _systemClock,
    this._reauthenticate,
  ]) : accountCurrency = _currency(accountCurrency);

  final String accountCurrency;
  final InvoiceClock _now;
  final InvoiceReauthentication? _reauthenticate;
  final Map<String, Invoice> _invoices = <String, Invoice>{};
  final Map<String, InvoiceReceipt> _receiptsByInvoice =
      <String, InvoiceReceipt>{};
  final Set<String> _receiptIds = <String>{};
  final Map<String, InvoiceDocument> _documents = <String, InvoiceDocument>{};
  final Map<String, List<InvoiceRefund>> _refunds =
      <String, List<InvoiceRefund>>{};
  final Map<String, InvoiceDispute> _disputes = <String, InvoiceDispute>{};
  final List<InvoiceAuditEvent> _audit = <InvoiceAuditEvent>[];
  int _refundSequence = 0;
  int _disputeSequence = 0;

  static DateTime _systemClock() => DateTime.now().toUtc();

  /// Newest first: the last thing that happened is the first thing to show.
  List<Invoice> get invoices => UnmodifiableListView(
    _invoices.values.toList(growable: false)
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt)),
  );

  List<InvoiceAuditEvent> get audit => UnmodifiableListView(_audit);

  List<InvoiceRefund> refundsFor(String invoiceId) => UnmodifiableListView(
    _refunds[_knownInvoice(invoiceId).invoiceId] ?? const [],
  );

  InvoiceDispute? disputeFor(String invoiceId) =>
      _disputes[_knownInvoice(invoiceId).invoiceId];

  /// Receipt for an invoice, or `null` when the provider issued none. A
  /// receipt is never generated locally.
  InvoiceReceipt? receiptFor(String invoiceId) =>
      _receiptsByInvoice[_knownInvoice(invoiceId).invoiceId];

  /// Effective payment verdict, including the derived refunded/disputed
  /// states that a provider snapshot may not declare.
  ///
  /// The dispute verdict is part of the verdict, not just its open/closed
  /// flag. It used to test `isOpen` alone, so a dispute the provider WON —
  /// money returned to the user — reported `paid`: the account was told it
  /// still owed a charge the provider had already reversed. [RefundState]
  /// and [DisputeState] are both provider decisions, and both now decide the
  /// invoice they belong to.
  InvoicePayment paymentStatusFor(String invoiceId) {
    final invoice = _knownInvoice(invoiceId);
    final dispute = _disputes[invoice.invoiceId];
    final settled = _settledRefundTotal(invoice.invoiceId);
    // A won chargeback is money the provider gave back, so it is refunded at
    // the full collected amount even though no [InvoiceRefund] was raised: the
    // dispute ledger is the receipt.
    final disputeRefund = dispute?.state == DisputeState.won
        ? (invoice.payment?.paidAmount ?? 0)
        : 0.0;
    final returned = settled + disputeRefund;
    final collected = invoice.payment?.paidAmount ?? 0;
    if (returned > 0 && collected > 0) {
      final returnedMinor = (returned * 100).round();
      final collectedMinor = (collected * 100).round();
      if (returnedMinor >= collectedMinor) {
        return _derived(InvoicePaymentState.refunded, invoice);
      }
      return _derived(InvoicePaymentState.partiallyRefunded, invoice);
    }
    if (dispute?.isOpen ?? false) {
      return _derived(InvoicePaymentState.disputed, invoice);
    }
    return invoice.payment ?? InvoicePayment(state: InvoicePaymentState.unpaid);
  }

  /// Remaining amount that may still be refunded for this invoice.
  ///
  /// Only a request that is still `requested` or has actually `settled` holds
  /// the budget. It used to subtract every refund ever raised, so a refund the
  /// provider rejected — money that never left the account — kept reducing the
  /// remainder, and a customer who had been refused twice could end up with
  /// nothing left to refund at all. A lost or withdrawn chargeback consumes
  /// nothing: the charge stands and stays refundable.
  double refundableRemaining(String invoiceId) {
    final invoice = _knownInvoice(invoiceId);
    final collected = invoice.payment?.paidAmount ?? 0;
    final held =
        _refunds[invoice.invoiceId]?.fold<double>(
          0,
          (sum, refund) => switch (refund.state) {
            RefundState.requested || RefundState.settled => sum + refund.amount,
            RefundState.rejected || RefundState.cancelled => sum,
          },
        ) ??
        0;
    if (_disputes[invoice.invoiceId]?.state == DisputeState.won) return 0;
    final remaining = collected - held;
    return remaining < 0 ? 0 : remaining;
  }

  /// Download descriptor. Deliberately carries no path: the document bytes
  /// are fetched by the billing provider, never from a local guess.
  Map<String, Object?> downloadDescriptor(String invoiceId) {
    final invoice = _knownInvoice(invoiceId);
    final document = _documents[invoice.invoiceId];
    if (document == null) {
      return <String, Object?>{'available': false};
    }
    return <String, Object?>{
      'available': true,
      'format': document.format.name,
      'byte_size': document.byteSize,
      'issued_at': document.issuedAt.toIso8601String(),
    };
  }

  void register(
    Invoice invoice, {
    InvoiceReceipt? receipt,
    InvoiceDocument? document,
  }) {
    if (_invoices.containsKey(invoice.invoiceId)) {
      throw StateError('Invoice ${invoice.invoiceId} is already registered.');
    }
    if (invoice.currency != accountCurrency) {
      throw ArgumentError.value(
        invoice.currency,
        'invoice',
        'Currency must match the account billing currency.',
      );
    }
    if (receipt != null) {
      if (receipt.invoiceId != invoice.invoiceId) {
        throw ArgumentError.value(
          receipt.invoiceId,
          'receipt.invoiceId',
          'A receipt must reference the invoice it is registered with.',
        );
      }
      if (receipt.currency != accountCurrency) {
        throw ArgumentError.value(
          receipt.currency,
          'receipt.currency',
          'Currency must match the account billing currency.',
        );
      }
      if (!_receiptIds.add(receipt.receiptId)) {
        throw StateError('Receipt ${receipt.receiptId} already exists.');
      }
      _receiptsByInvoice[invoice.invoiceId] = receipt;
    }
    if (document != null) {
      _documents[invoice.invoiceId] = document;
    }
    _invoices[invoice.invoiceId] = invoice;
    _record('register_invoice', invoice.invoiceId);
  }

  /// Requests a refund. Fails closed on unknown/unpaid invoices, on an empty
  /// reason, and once the cumulative requests would exceed what was
  /// collected. Requires reauthentication.
  Future<InvoiceRefund> requestRefund({
    required String invoiceId,
    required double amount,
    required String reason,
  }) async {
    final invoice = _knownInvoice(invoiceId);
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be finite and greater than zero.',
      );
    }
    final trimmed = _required(reason, 'reason');
    // Reauthentication is requested before the eligibility preconditions so a
    // refusal is always audited, and the cumulative bound is checked against
    // the budget that is actually left at that moment.
    if (!await _requireReauth('request_refund', invoice.invoiceId)) {
      throw StateError('Reauthentication is required to request a refund.');
    }
    final state = paymentStatusFor(invoice.invoiceId).state;
    final collected = invoice.payment?.paidAmount ?? 0;
    if (collected <= 0 ||
        (state != InvoicePaymentState.paid &&
            state != InvoicePaymentState.partiallyPaid &&
            state != InvoicePaymentState.partiallyRefunded)) {
      throw StateError(
        'Invoice ${invoice.invoiceId} has no settled payment to refund.',
      );
    }
    if (amount > refundableRemaining(invoice.invoiceId) + 0.0000001) {
      throw StateError('Refunds for this invoice exceed the collected amount.');
    }
    _refundSequence += 1;
    final refund = InvoiceRefund._(
      refundId: 'ref-${invoice.invoiceId}-$_refundSequence',
      invoiceId: invoice.invoiceId,
      amount: amount,
      reason: trimmed,
      requestedAt: _now().toUtc(),
    );
    _refunds
        .putIfAbsent(invoice.invoiceId, () => <InvoiceRefund>[])
        .add(refund);
    _record('request_refund', invoice.invoiceId);
    return refund;
  }

  /// Files a dispute against a paid invoice inside the provider's declared
  /// window. A provider that declared no window has none open, and an
  /// invoice with an open dispute cannot be disputed twice. Requires
  /// reauthentication.
  Future<InvoiceDispute> fileDispute({
    required String invoiceId,
    required String reason,
    Iterable<DisputeEvidence> evidence = const <DisputeEvidence>[],
  }) async {
    final invoice = _knownInvoice(invoiceId);
    final trimmed = _required(reason, 'reason');
    // Reauthentication is requested before the eligibility preconditions so a
    // refusal is always audited; a denied sensitive action is not silently
    // downgraded to "this invoice cannot be disputed".
    if (!await _requireReauth('file_dispute', invoice.invoiceId)) {
      throw StateError('Reauthentication is required to file a dispute.');
    }
    final state = paymentStatusFor(invoice.invoiceId).state;
    if (state == InvoicePaymentState.unpaid ||
        state == InvoicePaymentState.pending ||
        state == InvoicePaymentState.failed) {
      throw StateError(
        'Invoice ${invoice.invoiceId} has no settled payment to dispute.',
      );
    }
    final deadline = invoice.disputeDeadline;
    if (deadline == null) {
      throw StateError(
        'The provider declared no dispute window for ${invoice.invoiceId}.',
      );
    }
    final now = _now().toUtc();
    if (now.isAfter(deadline)) {
      throw StateError(
        'The dispute window for ${invoice.invoiceId} has closed.',
      );
    }
    if ((_disputes[invoice.invoiceId]?.isOpen ?? false)) {
      throw StateError('A dispute for ${invoice.invoiceId} is already open.');
    }
    _disputeSequence += 1;
    final dispute = InvoiceDispute._(
      disputeId: 'dsp-${invoice.invoiceId}-$_disputeSequence',
      invoiceId: invoice.invoiceId,
      reason: trimmed,
      filedAt: now,
      evidence: evidence,
    );
    _disputes[invoice.invoiceId] = dispute;
    _record('file_dispute', invoice.invoiceId);
    return dispute;
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'currency': accountCurrency,
    'billing_contract_status': billingContractStatus,
    'invoices': [
      for (final invoice in invoices)
        <String, Object?>{
          ...invoice.toPublicJson(),
          'refundable_remaining': refundableRemaining(invoice.invoiceId),
        },
    ],
    'refundable_remaining': invoices.fold<double>(
      0,
      (sum, invoice) => sum + refundableRemaining(invoice.invoiceId),
    ),
    'refunds': [
      for (final refunds in _refunds.values)
        for (final refund in refunds) refund.toPublicJson(),
    ],
    'disputes': [
      for (final dispute in _disputes.values)
        <String, Object?>{
          'dispute_id': dispute.disputeId,
          'invoice_id': dispute.invoiceId,
          'state': dispute.state.name,
          'filed_at': dispute.filedAt.toIso8601String(),
          'resolved_at': dispute.resolvedAt?.toIso8601String(),
          'evidence': dispute.evidence
              .map((item) => item.toPublicJson())
              .toList(growable: false),
        },
    ],
  };

  Invoice _knownInvoice(String invoiceId) {
    final normalized = _required(invoiceId, 'invoiceId');
    final found = _invoices[normalized];
    if (found == null) throw StateError('Unknown invoice $normalized.');
    return found;
  }

  InvoicePayment _derived(InvoicePaymentState state, Invoice invoice) =>
      InvoicePayment._derived(
        state: state,
        paidAmount: invoice.payment?.paidAmount,
        paidAt: invoice.payment?.paidAt,
        methodLabel: invoice.payment?.methodLabel,
      );

  double _settledRefundTotal(String invoiceId) {
    final refunds = _refunds[invoiceId];
    if (refunds == null) return 0;
    var minor = 0;
    for (final refund in refunds) {
      if (refund.state == RefundState.settled) {
        minor += (refund.amount * 100).round();
      }
    }
    return minor / 100;
  }

  Future<bool> _requireReauth(String action, String invoiceId) async {
    final broker = _reauthenticate;
    final allowed = broker != null && await broker();
    if (!allowed) _record('denied_$action', invoiceId);
    return allowed;
  }

  void _record(String action, String invoiceId) {
    _audit.add(
      InvoiceAuditEvent(
        action: action,
        invoiceId: invoiceId,
        at: _now().toUtc(),
      ),
    );
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String _currency(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.length != 3 || normalized.contains(RegExp('[^a-z]'))) {
    throw ArgumentError.value(value, 'currency', 'ISO 4217 code required.');
  }
  return normalized;
}

String _sha256(String value) {
  final normalized = value.trim().toLowerCase();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'sha256',
      'Lowercase hex digest required.',
    );
  }
  return normalized;
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, field, 'Must be UTC.');
  }
}

/// A billing surface may show a masked instrument reference and nothing
/// else. A 12+ digit run or card-shaped separators is raw card data and is
/// refused at the boundary.
String? _methodLabel(String? value) {
  if (value == null) return null;
  final normalized = _required(value, 'methodLabel');
  if (RegExp(r'\d{12,}').hasMatch(normalized) ||
      RegExp(r'\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}').hasMatch(normalized)) {
    throw InvoiceCardDataRefused(
      value,
      'methodLabel',
      'A full card number is never accepted; use the masked display label.',
    );
  }
  return normalized;
}
