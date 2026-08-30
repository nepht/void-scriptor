import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/communication_channel_profiles.dart';

void main() {
  group('Communication Channel Profiles (110.36)', () {
    group('courier', () {
      test(
        'validated factory accepts courier channel with physical delivery traits',
        () {
          final channel = CommunicationChannel.courier(
            id: 'royal-courier',
            label: 'Royal Courier',
            traits: const ChannelTraits(
              capacity: 5,
              latencyTicks: 24,
              reliability: 9,
              requiresTwoWay: false,
            ),
            access: const AccessPolicy(allowedSenders: {'crown'}),
            source: const ChannelSource(
              revision: 'r1',
              reason: 'heraldry book',
            ),
          );

          expect(channel.id, 'royal-courier');
          expect(channel.kind, CommunicationChannelKind.courier);
          expect(channel.label, 'Royal Courier');
          expect(channel.traits.capacity, 5);
          expect(channel.traits.latencyTicks, 24);
          expect(channel.traits.reliability, 9);
          expect(channel.access.allowedSenders, {'crown'});
        },
      );

      test('courier rejects empty id', () {
        expect(
          () => CommunicationChannel.courier(
            id: '',
            label: 'Bad',
            traits: const ChannelTraits(),
            access: const AccessPolicy(),
            source: const ChannelSource(revision: 'r1', reason: 'test'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('signal', () {
      test('signal channel carries visual-audio traits', () {
        final channel = CommunicationChannel.signal(
          id: 'beacon-fire',
          label: 'Beacon Fire',
          traits: const ChannelTraits(
            capacity: 1,
            latencyTicks: 0,
            reliability: 6,
            requiresTwoWay: false,
          ),
          access: const AccessPolicy(),
          source: const ChannelSource(revision: 'r2', reason: 'warden manual'),
        );

        expect(channel.kind, CommunicationChannelKind.signal);
        expect(channel.traits.requiresTwoWay, isFalse);
      });

      test('signal supports two-way acknowledgement flag', () {
        final channel = CommunicationChannel.signal(
          id: 'church-bell',
          label: 'Church Bell',
          traits: const ChannelTraits(requiresTwoWay: true),
          access: const AccessPolicy(),
          source: const ChannelSource(revision: 'r1', reason: 'test'),
        );
        expect(channel.traits.requiresTwoWay, isTrue);
      });
    });

    group('printing', () {
      test('printing channel has high capacity and broadcasts', () {
        final channel = CommunicationChannel.printing(
          id: 'town-press',
          label: 'Town Press',
          traits: const ChannelTraits(
            capacity: 1000,
            latencyTicks: 72,
            reliability: 7,
          ),
          access: const AccessPolicy(),
          source: const ChannelSource(
            revision: 'r1',
            reason: 'gazette charter',
          ),
        );

        expect(channel.kind, CommunicationChannelKind.printing);
        expect(channel.traits.capacity, 1000);
        expect(channel.traits.latencyTicks, 72);
      });

      test('printing rejects capacity <= 0', () {
        expect(
          () => CommunicationChannel.printing(
            id: 'broken',
            label: 'Broken Press',
            traits: const ChannelTraits(capacity: 0),
            access: const AccessPolicy(),
            source: const ChannelSource(revision: 'r1', reason: 'test'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('magic_or_technology', () {
      test('magicOrTechnology channel can be instantaneous and long-range', () {
        final channel = CommunicationChannel.magicOrTechnology(
          id: 'arcane-link',
          label: 'Arcane Link',
          traits: const ChannelTraits(
            capacity: 1,
            latencyTicks: 0,
            reliability: 8,
            requiresTwoWay: true,
          ),
          access: const AccessPolicy(requiresEncrypted: true),
          source: const ChannelSource(revision: 'r9', reason: 'spell catalog'),
        );

        expect(channel.kind, CommunicationChannelKind.magicOrTechnology);
        expect(channel.access.requiresEncrypted, isTrue);
      });

      test('magicOrTechnology supports custom identifiers via label', () {
        final channel = CommunicationChannel.magicOrTechnology(
          id: 'aether-relay',
          label: 'Aether Relay v2',
          traits: const ChannelTraits(requiresTwoWay: true),
          access: const AccessPolicy(),
          source: const ChannelSource(revision: 'r1', reason: 'tech log'),
        );
        expect(channel.label, contains('Aether'));
      });
    });

    group('custom_channel', () {
      test('custom channel preserves arbitrary kind marker', () {
        final channel = CommunicationChannel.custom(
          id: 'songbirds',
          label: 'Songbird Network',
          traits: const ChannelTraits(
            capacity: 4,
            latencyTicks: 12,
            reliability: 5,
          ),
          access: const AccessPolicy(),
          customKind: 'songbird',
          source: const ChannelSource(
            revision: 'r1',
            reason: 'naturalist notes',
          ),
        );

        expect(channel.kind, CommunicationChannelKind.custom);
        expect(channel.customKind, 'songbird');
      });

      test('custom channel rejects empty customKind', () {
        expect(
          () => CommunicationChannel.custom(
            id: 'broken',
            label: 'Broken',
            traits: const ChannelTraits(),
            access: const AccessPolicy(),
            customKind: '',
            source: const ChannelSource(revision: 'r1', reason: 'test'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('access_rules', () {
      test('allowedSenders restricts senders', () {
        const access = AccessPolicy(allowedSenders: {'crown', 'guild'});
        expect(access.allowsSender('crown'), isTrue);
        expect(access.allowsSender('guild'), isTrue);
        expect(access.allowsSender('bandit'), isFalse);
      });

      test('blockedSenders denies specific senders', () {
        const access = AccessPolicy(blockedSenders: {'traitor'});
        expect(access.allowsSender('traitor'), isFalse);
        expect(access.allowsSender('loyal'), isTrue);
      });

      test('requiresEncrypted blocks senders without encryption proof', () {
        const access = AccessPolicy(requiresEncrypted: true);
        expect(access.allowsSender('anyone', encrypted: true), isTrue);
        expect(access.allowsSender('anyone', encrypted: false), isFalse);
      });

      test('allowedRecipients restricts receivers', () {
        const access = AccessPolicy(allowedRecipients: {'ally'});
        expect(access.allowsRecipient('ally'), isTrue);
        expect(access.allowsRecipient('enemy'), isFalse);
      });

      test('registry enforces access when delivering a message', () {
        final registry = CommunicationChannelRegistry(
          channels: {
            CommunicationChannel.courier(
              id: 'cap-courier',
              label: 'Captain Courier',
              traits: const ChannelTraits(),
              access: const AccessPolicy(
                allowedSenders: {'captain'},
                blockedSenders: {'mutineer'},
              ),
              source: const ChannelSource(revision: 'r1', reason: 'log'),
            ),
          },
        );

        final ok = registry.deliver(
          channelId: 'cap-courier',
          senderId: 'captain',
          recipientId: 'crew',
          encrypted: false,
        );
        expect(ok.accepted, isTrue);

        final blocked = registry.deliver(
          channelId: 'cap-courier',
          senderId: 'mutineer',
          recipientId: 'crew',
          encrypted: false,
        );
        expect(blocked.accepted, isFalse);
        expect(blocked.denialReason, isNotNull);

        final unknown = registry.deliver(
          channelId: 'cap-courier',
          senderId: 'stranger',
          recipientId: 'crew',
          encrypted: false,
        );
        expect(unknown.accepted, isFalse);
      });

      test('access policy rejects empty id label and invalid reliability', () {
        expect(
          () => CommunicationChannel.courier(
            id: 'x',
            label: '',
            traits: const ChannelTraits(),
            access: const AccessPolicy(),
            source: const ChannelSource(revision: 'r1', reason: 'test'),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => CommunicationChannel.signal(
            id: 'x',
            label: 'X',
            traits: const ChannelTraits(reliability: 11),
            access: const AccessPolicy(),
            source: const ChannelSource(revision: 'r1', reason: 'test'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('registry', () {
      test('registry rejects duplicate ids and unknown lookups', () {
        final channel = CommunicationChannel.signal(
          id: 'shared',
          label: 'Shared',
          traits: const ChannelTraits(),
          access: const AccessPolicy(),
          source: const ChannelSource(revision: 'r1', reason: 'test'),
        );
        final dupe = CommunicationChannel.signal(
          id: 'shared',
          label: 'Shared 2',
          traits: const ChannelTraits(),
          access: const AccessPolicy(),
          source: const ChannelSource(revision: 'r2', reason: 'log'),
        );
        expect(
          () => CommunicationChannelRegistry(channels: {channel, dupe}),
          throwsA(isA<ArgumentError>()),
        );

        final registry = CommunicationChannelRegistry(channels: {channel});
        expect(registry.byId('shared'), channel);
        expect(registry.byId('missing'), isNull);
        expect(
          registry.byKind(CommunicationChannelKind.signal),
          contains(channel),
        );
      });
    });
  });
}
