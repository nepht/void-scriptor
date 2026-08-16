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
    var tick = DateTime(2026, 1, 1);
    final presence = Presence(
      avatarId: 'av1',
      zoneId: 'z1',
      now: () => tick,
    );
    final before = presence.lastSeen;
    tick = tick.add(const Duration(seconds: 1));
    presence.moveTo('z3');
    expect(presence.lastSeen, isNot(before));
    expect(presence.lastSeen, tick);
  });
}
