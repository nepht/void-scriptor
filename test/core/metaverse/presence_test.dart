import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/metaverse/presence/avatar.dart';
import 'package:void_scriptor/core/metaverse/presence/presence.dart';

void main() {
  test('Avatar holds identity and appearance', () {
    const avatar = Avatar(
      id: 'av1',
      name: 'Nephthys',
      appearance: 'void warden',
    );
    expect(avatar.name, 'Nephthys');
    expect(avatar.appearance, 'void warden');
  });

  test('Presence holds zone and updates', () {
    final presence = Presence(avatarId: 'av1', zoneId: 'z1');
    expect(presence.zoneId, 'z1');
    presence.moveTo('z2');
    expect(presence.zoneId, 'z2');
    expect(presence.lastSeen, isNotNull);
  });

  test('Presence tracks lastSeen on update', () {
    final presence = Presence(avatarId: 'av1', zoneId: 'z1');
    final before = presence.lastSeen;
    presence.moveTo('z3');
    expect(presence.lastSeen, isNot(before));
  });
}
