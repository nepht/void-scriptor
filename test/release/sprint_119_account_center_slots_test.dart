import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_account_center_slots.dart';

void main() {
  const declaredSlots = <String>{
    'provider_tile',
    'connection_detail',
    'settings_form',
    'usage_card',
    'health_status',
    'action_menu',
  };
  const declaredActions = <String>{
    'actionref:alpha:open-settings',
    'actionref:alpha:reconnect',
  };

  SlotContribution contribution({
    AccountCenterSlot slot = AccountCenterSlot.providerTile,
    String providerRef = 'provref:alpha:connector',
    String title = 'Alpha Provider',
    String body = 'Connected.',
    int order = 0,
    String? actionRef,
    Map<String, String> attributes = const <String, String>{},
  }) => SlotContribution(
    slot: slot,
    providerRef: providerRef,
    title: title,
    body: body,
    order: order,
    actionRef: actionRef,
    attributes: attributes,
  );

  group('119.19 Account Center UI Extension Slots', () {
    test('the canonical slot vocabulary is closed', () {
      expect(AccountCenterSlots.requiredSlots, <String>[
        'provider_tile',
        'connection_detail',
        'settings_form',
        'usage_card',
        'health_status',
        'action_menu',
      ]);
      for (final slot in declaredSlots) {
        expect(AccountCenterSlots.isAllowedSlot(slot), isTrue);
      }
      expect(AccountCenterSlots.isAllowedSlot('arbitrary_canvas'), isFalse);
      expect(AccountCenterSlots.isAllowedSlot(''), isFalse);
      expect(AccountCenterSlots.slotName(AccountCenterSlot.unknown), isNull);
      expect(
        AccountCenterSlots.slotName(AccountCenterSlot.usageCard),
        'usage_card',
      );
    });

    test('a valid contribution is accepted and a render is deterministic', () {
      final rendered = AccountCenterSlots.render(
        slot: 'provider_tile',
        declaredSlots: declaredSlots,
        declaredActions: declaredActions,
        contributions: <SlotContribution>[
          contribution(providerRef: 'provref:alpha:connector', order: 2),
          contribution(providerRef: 'provref:beta:connector', order: 1),
          contribution(providerRef: 'provref:gamma:connector', order: 1),
        ],
      );

      expect(
        rendered.map((SlotContribution c) => c.providerRef).toList(),
        <String>[
          'provref:beta:connector',
          'provref:gamma:connector',
          'provref:alpha:connector',
        ],
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        isEmpty,
      );
    });

    test(
      'an undeclared slot and an undeclared contribution slot are refused',
      () {
        expect(
          AccountCenterSlots.validateContribution(
            contribution: contribution(slot: AccountCenterSlot.unknown),
            declaredSlots: declaredSlots,
            declaredActions: declaredActions,
          ),
          contains('slot_unknown'),
        );
        expect(
          AccountCenterSlots.validateContribution(
            contribution: contribution(),
            declaredSlots: const <String>{'usage_card'},
            declaredActions: declaredActions,
          ),
          contains('slot_not_declared'),
        );
      },
    );

    test('arbitrary layout injection is refused', () {
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            attributes: const <String, String>{
              'widget': 'Container',
              'layout': 'Stack',
              'style': 'position:absolute',
              'html': '<div>',
              'ontap': 'navigate()',
              'width': '999',
            },
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('attribute_key_forbidden'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            attributes: const <String, String>{'mystery_key': 'x'},
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('attribute_key_unknown'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            attributes: const <String, String>{'label': '<b>x</b>'},
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('attribute_value_not_plain'),
      );
      expect(
        AccountCenterSlots.hasLayoutInjection(const <String, String>{
          'color': '#fff',
        }),
        isTrue,
      );
      expect(
        AccountCenterSlots.hasLayoutInjection(const <String, String>{
          'label': 'Usage',
        }),
        isFalse,
      );
    });

    test(
      'markup, interpolation, links, and control characters are not plain text',
      () {
        expect(AccountCenterSlots.isPlainText('Alpha Provider'), isTrue);
        expect(AccountCenterSlots.isPlainText('Terhubung — siap.'), isTrue);
        expect(AccountCenterSlots.isPlainText('<b>Bold</b>'), isFalse);
        expect(AccountCenterSlots.isPlainText('a &amp; b'), isFalse);
        expect(AccountCenterSlots.isPlainText('{value}'), isFalse);
        expect(AccountCenterSlots.isPlainText(r'${injected}'), isFalse);
        expect(
          AccountCenterSlots.isPlainText('https://evil.example/x'),
          isFalse,
        );
        expect(AccountCenterSlots.isPlainText('line\u0007break'), isFalse);
        expect(
          AccountCenterSlots.validateContribution(
            contribution: contribution(title: '<b>Bold</b>'),
            declaredSlots: declaredSlots,
            declaredActions: declaredActions,
          ),
          contains('text_not_plain'),
        );
      },
    );

    test('length bounds are enforced', () {
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(title: ''),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('title_empty'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            title: List<String>.filled(81, 'a').join(),
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('title_too_long'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            body: List<String>.filled(2001, 'b').join(),
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('body_too_long'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(
            title: List<String>.filled(80, 'a').join(),
            body: List<String>.filled(2000, 'b').join(),
          ),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        isEmpty,
      );
    });

    test('actions must be declared opaque handles', () {
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(actionRef: 'actionref:alpha:reconnect'),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        isEmpty,
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(actionRef: 'actionref:alpha:delete-all'),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('action_not_declared'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(actionRef: 'open-settings'),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('action_ref_invalid'),
      );
    });

    test('provider references must be opaque handles', () {
      expect(
        AccountCenterSlots.isValidProviderRef('provref:alpha:connector'),
        isTrue,
      );
      expect(AccountCenterSlots.isValidProviderRef('alpha'), isFalse);
      expect(AccountCenterSlots.isValidProviderRef('provref:alpha'), isFalse);
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(providerRef: 'alpha'),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('provider_ref_invalid'),
      );
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(order: -1),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
        ),
        contains('order_negative'),
      );
    });

    test('a duplicate contribution from one provider is refused', () {
      expect(
        AccountCenterSlots.validateContribution(
          contribution: contribution(),
          declaredSlots: declaredSlots,
          declaredActions: declaredActions,
          peers: <SlotContribution>[contribution(order: 1)],
        ),
        contains('duplicate_slot_contribution'),
      );
    });

    test('render is fail-closed per provider and never partially applies', () {
      final rendered = AccountCenterSlots.render(
        slot: 'provider_tile',
        declaredSlots: declaredSlots,
        declaredActions: declaredActions,
        contributions: <SlotContribution>[
          contribution(providerRef: 'provref:alpha:connector'),
          contribution(
            providerRef: 'provref:alpha:connector',
            title: '<b>Injected</b>',
          ),
          contribution(providerRef: 'provref:beta:connector'),
          contribution(
            providerRef: 'provref:gamma:connector',
            attributes: const <String, String>{'widget': 'Stack'},
          ),
        ],
      );

      expect(
        rendered.map((SlotContribution c) => c.providerRef).toList(),
        <String>['provref:beta:connector'],
      );
    });

    test('diagnostics redact provider and action references', () {
      expect(
        AccountCenterSlots.redact(
          'provref:alpha:connector actionref:alpha:reconnect',
        ),
        '[REDACTED] [REDACTED]',
      );
      expect(
        AccountCenterSlots.redact('provider provref:alpha:connector rejected'),
        'provider [REDACTED] rejected',
      );
    });

    test('validates the canonical manifest slot vocabulary', () {
      expect(AccountCenterSlots.validateCanonicalManifest(), isEmpty);

      expect(
        AccountCenterSlots.validateManifest(<String, dynamic>{
          'canonical_step': '119.19',
          'unknown_field_policy': 'REJECT',
          'allowed_slots': <String, dynamic>{
            'provider_tile': <String, dynamic>{},
            'usage_card': <String, dynamic>{},
          },
        }),
        containsAll(<String>[
          'slot_missing:connection_detail',
          'slot_missing:action_menu',
        ]),
      );
      expect(
        AccountCenterSlots.validateManifest(<String, dynamic>{
          'canonical_step': '119.18',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
          'slot_missing:provider_tile',
        ]),
      );
    });
  });
}
