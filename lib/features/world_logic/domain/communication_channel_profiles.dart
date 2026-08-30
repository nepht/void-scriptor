// Communication Channel Profiles — Sprint 110.36.
// Domain-only model for courier / signal / printing / magic-technology / custom
// channels with capacity, latency, reliability, access rules, and registry-level
// delivery guard.

enum CommunicationChannelKind {
  courier,
  signal,
  printing,
  magicOrTechnology,
  custom,
}

class ChannelSource {
  final String revision;
  final String reason;
  const ChannelSource({required this.revision, required this.reason});
}

class ChannelTraits {
  final int capacity;
  final int latencyTicks;
  final int reliability;
  final bool requiresTwoWay;

  const ChannelTraits({
    this.capacity = 1,
    this.latencyTicks = 0,
    this.reliability = 5,
    this.requiresTwoWay = false,
  });
}

class AccessPolicy {
  final Set<String> allowedSenders;
  final Set<String> blockedSenders;
  final Set<String> allowedRecipients;
  final bool requiresEncrypted;

  const AccessPolicy({
    this.allowedSenders = const {},
    this.blockedSenders = const {},
    this.allowedRecipients = const {},
    this.requiresEncrypted = false,
  });

  bool allowsSender(String senderId, {bool encrypted = false}) {
    if (blockedSenders.contains(senderId)) {
      return false;
    }
    if (allowedSenders.isNotEmpty && !allowedSenders.contains(senderId)) {
      return false;
    }
    if (requiresEncrypted && !encrypted) {
      return false;
    }
    return true;
  }

  bool allowsRecipient(String recipientId) {
    if (allowedRecipients.isEmpty) {
      return true;
    }
    return allowedRecipients.contains(recipientId);
  }
}

class CommunicationChannel {
  final String id;
  final String label;
  final CommunicationChannelKind kind;
  final String? customKind;
  final ChannelTraits traits;
  final AccessPolicy access;
  final ChannelSource source;

  const CommunicationChannel._({
    required this.id,
    required this.label,
    required this.kind,
    this.customKind,
    required this.traits,
    required this.access,
    required this.source,
  });

  factory CommunicationChannel.courier({
    required String id,
    required String label,
    required ChannelTraits traits,
    required AccessPolicy access,
    required ChannelSource source,
  }) {
    _validateBase(id, label, traits);
    return CommunicationChannel._(
      id: id,
      label: label,
      kind: CommunicationChannelKind.courier,
      traits: traits,
      access: access,
      source: source,
    );
  }

  factory CommunicationChannel.signal({
    required String id,
    required String label,
    required ChannelTraits traits,
    required AccessPolicy access,
    required ChannelSource source,
  }) {
    _validateBase(id, label, traits);
    return CommunicationChannel._(
      id: id,
      label: label,
      kind: CommunicationChannelKind.signal,
      traits: traits,
      access: access,
      source: source,
    );
  }

  factory CommunicationChannel.printing({
    required String id,
    required String label,
    required ChannelTraits traits,
    required AccessPolicy access,
    required ChannelSource source,
  }) {
    _validateBase(id, label, traits);
    if (traits.capacity <= 0) {
      throw ArgumentError.value(
        traits.capacity,
        'capacity',
        'printing channel capacity must be > 0',
      );
    }
    return CommunicationChannel._(
      id: id,
      label: label,
      kind: CommunicationChannelKind.printing,
      traits: traits,
      access: access,
      source: source,
    );
  }

  factory CommunicationChannel.magicOrTechnology({
    required String id,
    required String label,
    required ChannelTraits traits,
    required AccessPolicy access,
    required ChannelSource source,
  }) {
    _validateBase(id, label, traits);
    return CommunicationChannel._(
      id: id,
      label: label,
      kind: CommunicationChannelKind.magicOrTechnology,
      traits: traits,
      access: access,
      source: source,
    );
  }

  factory CommunicationChannel.custom({
    required String id,
    required String label,
    required ChannelTraits traits,
    required AccessPolicy access,
    required String customKind,
    required ChannelSource source,
  }) {
    _validateBase(id, label, traits);
    if (customKind.isEmpty) {
      throw ArgumentError.value(
        customKind,
        'customKind',
        'custom channel kind must be non-empty',
      );
    }
    return CommunicationChannel._(
      id: id,
      label: label,
      kind: CommunicationChannelKind.custom,
      customKind: customKind,
      traits: traits,
      access: access,
      source: source,
    );
  }

  static void _validateBase(String id, String label, ChannelTraits traits) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'channel id must be non-empty');
    }
    if (label.isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'channel label must be non-empty',
      );
    }
    if (traits.reliability < 0 || traits.reliability > 10) {
      throw ArgumentError.value(
        traits.reliability,
        'reliability',
        'reliability must be in [0,10]',
      );
    }
  }
}

class ChannelDeliveryResult {
  final bool accepted;
  final String? denialReason;
  const ChannelDeliveryResult._({required this.accepted, this.denialReason});

  factory ChannelDeliveryResult.accepted() =>
      const ChannelDeliveryResult._(accepted: true);

  factory ChannelDeliveryResult.denied(String reason) =>
      ChannelDeliveryResult._(accepted: false, denialReason: reason);
}

class CommunicationChannelRegistry {
  final Map<String, CommunicationChannel> _byId;

  CommunicationChannelRegistry({required Set<CommunicationChannel> channels})
    : _byId = Map.unmodifiable({
        for (final ch in channels)
          if (ch.id.isNotEmpty) ch.id: ch,
      }) {
    if (channels.length != _byId.length) {
      throw ArgumentError(
        'CommunicationChannelRegistry requires unique channel ids',
      );
    }
  }

  CommunicationChannel? byId(String id) => _byId[id];

  List<CommunicationChannel> byKind(CommunicationChannelKind kind) {
    return _byId.values.where((c) => c.kind == kind).toList(growable: false);
  }

  Iterable<CommunicationChannel> get channels => _byId.values;

  ChannelDeliveryResult deliver({
    required String channelId,
    required String senderId,
    required String recipientId,
    bool encrypted = false,
  }) {
    final channel = _byId[channelId];
    if (channel == null) {
      return ChannelDeliveryResult.denied('unknown channel "$channelId"');
    }
    if (!channel.access.allowsSender(senderId, encrypted: encrypted)) {
      return ChannelDeliveryResult.denied(
        'sender "$senderId" blocked by channel "${channel.id}"',
      );
    }
    if (!channel.access.allowsRecipient(recipientId)) {
      return ChannelDeliveryResult.denied(
        'recipient "$recipientId" not in allowed recipients',
      );
    }
    return ChannelDeliveryResult.accepted();
  }
}
