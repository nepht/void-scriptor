import 'package:flutter/material.dart';
import 'inspector_body.dart';

class WeaponInspector extends StatelessWidget {
  const WeaponInspector({super.key, required this.weaponId});
  final String weaponId;
  @override
  Widget build(BuildContext context) => InspectorBody(
    name: weaponId,
    type: 'Weapon',
    sections: const ['Properties', 'Combat', 'Relations'],
  );
}
