import 'dart:convert';
import 'dart:io';

/// The extension slots the Account Center exposes to connectors.
///
/// The vocabulary is closed. A connector may contribute data to a declared
/// slot; it may never contribute a layout, a style, or a handler.
enum AccountCenterSlot {
  /// A tile in the provider list.
  providerTile,

  /// Read-only detail for one connection.
  connectionDetail,

  /// Presentation of a connector's declared settings.
  settingsForm,

  /// Usage and quota summary for one connection.
  usageCard,

  /// Health and availability summary for one connection.
  healthStatus,

  /// Declared actions a connector may offer.
  actionMenu,

  /// A slot this build does not know. Always refused.
  unknown,
}

/// One connector contribution to an Account Center slot.
///
/// The payload is deliberately data-only: plain text plus an optional declared
/// action reference. There is no field through which a widget, a layout, a
/// style, a route, or a callback could be injected.
final class SlotContribution {
  const SlotContribution({
    required this.slot,
    required this.providerRef,
    required this.title,
    required this.body,
    required this.order,
    this.actionRef,
    this.attributes = const <String, String>{},
  });

  /// The slot this contribution targets.
  final AccountCenterSlot slot;

  /// The opaque provider reference that owns this contribution.
  final String providerRef;

  /// The plain-text title.
  final String title;

  /// The plain-text body.
  final String body;

  /// The host-ordering hint. Lower sorts first.
  final int order;

  /// An optional opaque reference to a previously declared action.
  final String? actionRef;

  /// Plain-text key/value pairs drawn from a closed key vocabulary.
  final Map<String, String> attributes;

  /// A redacted projection; references are never serialized.
  Map<String, Object?> toJson() => <String, Object?>{
    'slot': slot.name,
    'provider_ref': '[REDACTED]',
    'title': title,
    'body': body,
    'order': order,
    'action_ref': actionRef == null ? null : '[REDACTED]',
    'attributes': attributes,
  };

  @override
  String toString() => 'SlotContribution(${slot.name}, order: $order)';
}

/// The local Account Center UI extension slot contract for roadmap step 119.19.
///
/// Contributions are validated against a closed slot vocabulary and a closed
/// attribute key vocabulary, and every rejection is fail-closed: a provider
/// whose contribution is invalid has all of its contributions for that slot
/// dropped rather than partially applied.
abstract final class AccountCenterSlots {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_account_center_slots.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.19';

  /// The canonical slot vocabulary, in canonical order.
  static const List<String> requiredSlots = <String>[
    'provider_tile',
    'connection_detail',
    'settings_form',
    'usage_card',
    'health_status',
    'action_menu',
  ];

  /// This step declares no named methods.
  static const List<String> requiredMethods = <String>[];

  /// This step declares no acceptance map.
  static const List<String> requiredAcceptance = <String>[];

  /// The longest accepted title.
  static const int titleMaxLength = 80;

  /// The longest accepted body.
  static const int bodyMaxLength = 2000;

  /// Attribute keys a connector may contribute.
  static const Set<String> allowedAttributeKeys = <String>{
    'label',
    'value',
    'unit',
    'status',
    'detail',
    'count',
    'note',
  };

  /// Attribute keys that would let a connector inject layout or behavior.
  static const Set<String> forbiddenAttributeKeys = <String>{
    'widget',
    'layout',
    'style',
    'css',
    'class',
    'html',
    'script',
    'ontap',
    'onpress',
    'handler',
    'callback',
    'route',
    'navigator',
    'position',
    'color',
    'width',
    'height',
    'padding',
    'margin',
    'transform',
    'animation',
  };

  static final RegExp _unsafeText = RegExp(
    r'[<>&`\\{}]|\$|[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]',
  );

  static final RegExp _providerRef = RegExp(
    r'^provref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _actionRef = RegExp(
    r'^actionref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _secretRef = RegExp(
    r'\b(?:provref|actionref|evtref|idemref|payref|chkref|invref|modelref|'
    r'assetref|orgref|resref|jobref|whsec|sk_live|pk_live)'
    r':[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}\b',
    caseSensitive: false,
  );

  /// The canonical snake-case name of [slot], or `null` when unknown.
  static String? slotName(AccountCenterSlot slot) => switch (slot) {
    AccountCenterSlot.providerTile => 'provider_tile',
    AccountCenterSlot.connectionDetail => 'connection_detail',
    AccountCenterSlot.settingsForm => 'settings_form',
    AccountCenterSlot.usageCard => 'usage_card',
    AccountCenterSlot.healthStatus => 'health_status',
    AccountCenterSlot.actionMenu => 'action_menu',
    AccountCenterSlot.unknown => null,
  };

  /// Whether [slot] is in the closed canonical vocabulary.
  static bool isAllowedSlot(String slot) => requiredSlots.contains(slot);

  /// Whether [value] is plain text.
  ///
  /// Markup delimiters, entity ampersands, interpolation, backticks, braces,
  /// backslashes, raw links, and control characters are refused rather than
  /// sanitized, so a slot can never carry markup into the host.
  static bool isPlainText(String value) {
    if (_unsafeText.hasMatch(value)) {
      return false;
    }
    return !value.contains('://');
  }

  /// Whether [attributes] contains a key that could inject layout or behavior.
  static bool hasLayoutInjection(Map<String, String> attributes) =>
      attributes.keys.any((String key) {
        final normalized = key.toLowerCase();
        return forbiddenAttributeKeys.contains(normalized) ||
            !allowedAttributeKeys.contains(normalized);
      });

  /// Whether [value] is a well-formed opaque provider reference.
  static bool isValidProviderRef(String value) => _providerRef.hasMatch(value);

  /// Whether [value] is a well-formed opaque action reference.
  static bool isValidActionRef(String value) => _actionRef.hasMatch(value);

  /// Validates one contribution and returns the diagnostics that failed.
  static List<String> validateContribution({
    required SlotContribution contribution,
    required Set<String> declaredSlots,
    required Set<String> declaredActions,
    Iterable<SlotContribution> peers = const <SlotContribution>[],
  }) {
    final diagnostics = <String>[];

    final name = slotName(contribution.slot);
    if (name == null) {
      diagnostics.add('slot_unknown');
    } else if (!declaredSlots.contains(name)) {
      diagnostics.add('slot_not_declared');
    }

    if (!isValidProviderRef(contribution.providerRef)) {
      diagnostics.add('provider_ref_invalid');
    }

    if (contribution.title.isEmpty) {
      diagnostics.add('title_empty');
    } else if (contribution.title.length > titleMaxLength) {
      diagnostics.add('title_too_long');
    }

    if (contribution.body.length > bodyMaxLength) {
      diagnostics.add('body_too_long');
    }

    if (!isPlainText(contribution.title) || !isPlainText(contribution.body)) {
      diagnostics.add('text_not_plain');
    }

    if (contribution.order < 0) {
      diagnostics.add('order_negative');
    }

    final actionRef = contribution.actionRef;
    if (actionRef != null) {
      if (!isValidActionRef(actionRef)) {
        diagnostics.add('action_ref_invalid');
      } else if (!declaredActions.contains(actionRef)) {
        diagnostics.add('action_not_declared');
      }
    }

    for (final entry in contribution.attributes.entries) {
      final normalized = entry.key.toLowerCase();
      if (forbiddenAttributeKeys.contains(normalized)) {
        diagnostics.add('attribute_key_forbidden');
      } else if (!allowedAttributeKeys.contains(normalized)) {
        diagnostics.add('attribute_key_unknown');
      } else if (!isPlainText(entry.value)) {
        diagnostics.add('attribute_value_not_plain');
      }
    }

    for (final peer in peers) {
      if (peer.providerRef == contribution.providerRef &&
          peer.slot == contribution.slot) {
        diagnostics.add('duplicate_slot_contribution');
        break;
      }
    }

    return diagnostics;
  }

  /// Renders one slot, fail-closed per provider.
  ///
  /// A provider whose contribution is invalid, or that submits more than one
  /// contribution to the same slot, has every contribution for that slot
  /// dropped. The survivors are ordered by host order then provider reference,
  /// so a render is deterministic.
  static List<SlotContribution> render({
    required String slot,
    required Set<String> declaredSlots,
    required Set<String> declaredActions,
    required Iterable<SlotContribution> contributions,
  }) {
    final candidates = contributions
        .where(
          (SlotContribution contribution) =>
              slotName(contribution.slot) == slot,
        )
        .toList(growable: false);

    final counts = <String, int>{};
    for (final candidate in candidates) {
      counts[candidate.providerRef] = (counts[candidate.providerRef] ?? 0) + 1;
    }

    final rejected = <String>{};
    for (final candidate in candidates) {
      final diagnostics = validateContribution(
        contribution: candidate,
        declaredSlots: declaredSlots,
        declaredActions: declaredActions,
      );
      if (diagnostics.isNotEmpty) {
        rejected.add(candidate.providerRef);
      }
    }
    for (final entry in counts.entries) {
      if (entry.value > 1) {
        rejected.add(entry.key);
      }
    }

    final accepted = candidates
        .where(
          (SlotContribution contribution) =>
              !rejected.contains(contribution.providerRef),
        )
        .toList();
    accepted.sort((SlotContribution a, SlotContribution b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.providerRef.compareTo(b.providerRef);
    });
    return List<SlotContribution>.unmodifiable(accepted);
  }

  /// Replaces opaque references in [text] so a diagnostic cannot leak one.
  static String redact(String text) =>
      text.replaceAll(_secretRef, '[REDACTED]');

  /// Validates a manifest against this step's contract.
  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];

    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final slots = manifest['allowed_slots'];
    final declared = slots is Map
        ? slots.keys.map((Object? key) => '$key').toSet()
        : const <String>{};
    for (final required in requiredSlots) {
      if (!declared.contains(required)) {
        diagnostics.add('slot_missing:$required');
      }
    }

    if (requiredAcceptance.isNotEmpty) {
      final acceptance = manifest['acceptance'];
      final declaredAcceptance = acceptance is Map
          ? acceptance.keys.map((Object? key) => '$key').toSet()
          : const <String>{};
      for (final required in requiredAcceptance) {
        if (!declaredAcceptance.contains(required)) {
          diagnostics.add('acceptance_missing:$required');
        }
      }
    }

    if (requiredMethods.isNotEmpty) {
      final methods = manifest['required_methods'];
      final declaredMethods = methods is List
          ? methods.map((Object? method) => '$method').toSet()
          : const <String>{};
      for (final required in requiredMethods) {
        if (!declaredMethods.contains(required)) {
          diagnostics.add('method_missing:$required');
        }
      }
    }

    return diagnostics;
  }

  /// Validates the committed canonical manifest for this step.
  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return <String>['manifest_missing:$manifestPath'];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return <String>['manifest_not_an_object:$manifestPath'];
    }
    return validateManifest(decoded);
  }
}
