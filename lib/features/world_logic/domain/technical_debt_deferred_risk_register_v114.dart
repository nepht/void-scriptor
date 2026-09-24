/// Fail-closed technical-debt and deferred-risk ownership contract for
/// Sprint 114.42.
library;

enum TechnicalDebtDeferredRiskState { pass, fail, blocked }

enum TechnicalDebtDeferredRiskKind {
  technicalDebt,
  deferredRisk,
  externalEvidence,
}

class TechnicalDebtDeferredRiskItem {
  TechnicalDebtDeferredRiskItem({
    required this.itemId,
    required this.kind,
    required this.item,
    required this.impact,
    required List<String> evidence,
    required this.reasonDeferred,
    required this.owner,
    required this.target,
    required this.trigger,
  }) : evidence = List<String>.unmodifiable(evidence);

  final String itemId;
  final TechnicalDebtDeferredRiskKind kind;
  final String item;
  final String impact;
  final List<String> evidence;
  final String reasonDeferred;
  final String owner;
  final String target;
  final String trigger;

  TechnicalDebtDeferredRiskItem copyWith({
    String? itemId,
    TechnicalDebtDeferredRiskKind? kind,
    String? item,
    String? impact,
    List<String>? evidence,
    String? reasonDeferred,
    String? owner,
    String? target,
    String? trigger,
  }) {
    return TechnicalDebtDeferredRiskItem(
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      item: item ?? this.item,
      impact: impact ?? this.impact,
      evidence: evidence ?? this.evidence,
      reasonDeferred: reasonDeferred ?? this.reasonDeferred,
      owner: owner ?? this.owner,
      target: target ?? this.target,
      trigger: trigger ?? this.trigger,
    );
  }

  static List<String> missingFields(TechnicalDebtDeferredRiskItem item) {
    final missing = <String>[];
    if (item.item.trim().isEmpty) missing.add('item');
    if (item.impact.trim().isEmpty) missing.add('impact');
    if (item.evidence.isEmpty ||
        item.evidence.any((value) => value.trim().isEmpty)) {
      missing.add('evidence');
    }
    if (item.reasonDeferred.trim().isEmpty) missing.add('reason_deferred');
    if (item.owner.trim().isEmpty) missing.add('owner');
    if (item.target.trim().isEmpty) missing.add('target');
    if (item.trigger.trim().isEmpty) missing.add('trigger');
    return List<String>.unmodifiable(missing);
  }
}

class TechnicalDebtDeferredRiskRegisterDraft {
  TechnicalDebtDeferredRiskRegisterDraft({
    required List<TechnicalDebtDeferredRiskItem> items,
    List<String> itemIds = const <String>[],
  }) : items = List<TechnicalDebtDeferredRiskItem>.unmodifiable(items),
       itemIds = List<String>.unmodifiable(itemIds);

  final List<TechnicalDebtDeferredRiskItem> items;
  final List<String> itemIds;
}

class TechnicalDebtDeferredRiskRegisterReport {
  TechnicalDebtDeferredRiskRegisterReport({
    required this.state,
    required List<TechnicalDebtDeferredRiskItem> items,
    required List<String> violations,
    required List<String> limitations,
  }) : items = List<TechnicalDebtDeferredRiskItem>.unmodifiable(items),
       violations = List<String>.unmodifiable(violations),
       limitations = List<String>.unmodifiable(limitations);

  final TechnicalDebtDeferredRiskState state;
  final List<TechnicalDebtDeferredRiskItem> items;
  final List<String> violations;
  final List<String> limitations;

  int get itemCount => items.length;
}

abstract final class TechnicalDebtDeferredRiskRegisterContract {
  static const String canonicalStep = '114.42';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_technical_debt_deferred_risk_register.json';

  static const List<String> requiredFields = <String>[
    'item',
    'impact',
    'evidence',
    'reason_deferred',
    'owner',
    'target',
    'trigger',
  ];
}

class TechnicalDebtDeferredRiskRegisterGate {
  TechnicalDebtDeferredRiskRegisterReport evaluate(
    TechnicalDebtDeferredRiskRegisterDraft? draft,
  ) {
    if (draft == null || draft.items.isEmpty) {
      return TechnicalDebtDeferredRiskRegisterReport(
        state: TechnicalDebtDeferredRiskState.blocked,
        items: const <TechnicalDebtDeferredRiskItem>[],
        violations: const <String>[],
        limitations: const <String>[
          'No technical-debt or deferred-risk register is available; absence of debt is not claimed.',
        ],
      );
    }

    final violations = <String>[];
    final seenIds = <String>{};
    final itemIds = draft.itemIds
        .map((itemId) => itemId.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toList(growable: false);
    if (itemIds.length != draft.itemIds.length) {
      violations.add('blank_item_id');
    }
    for (final normalized in itemIds) {
      if (!seenIds.add(normalized)) {
        violations.add('duplicate_$normalized');
      }
    }
    for (final itemId in itemIds) {
      if (!draft.items.any((item) => item.itemId.trim() == itemId)) {
        violations.add('unknown_$itemId');
      }
    }
    for (final item in draft.items) {
      final normalized = item.itemId.trim();
      if (normalized.isEmpty) {
        violations.add('blank_item_id');
      } else if (!seenIds.contains(normalized)) {
        violations.add('unknown_$normalized');
      }
      for (final field in TechnicalDebtDeferredRiskItem.missingFields(item)) {
        violations.add(
          '${normalized.isEmpty ? '<unknown>' : normalized} missing $field',
        );
      }
    }

    return TechnicalDebtDeferredRiskRegisterReport(
      state: violations.isEmpty
          ? TechnicalDebtDeferredRiskState.pass
          : TechnicalDebtDeferredRiskState.fail,
      items: draft.items,
      violations: violations,
      limitations: <String>[
        'A deferred item requires an impact, evidence, reason, owner, target, and trigger.',
        'External publication, hosted CI, telemetry, signing, hardware, and live release evidence are not implied by this local register.',
      ],
    );
  }
}
