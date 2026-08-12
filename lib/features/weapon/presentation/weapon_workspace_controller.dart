import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/weapon_repository_impl.dart';
import '../domain/weapon_model.dart';

final weaponWorkspaceProvider = FutureProvider.family<WeaponModel?, String>((
  ref,
  weaponId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  return WeaponRepositoryImpl(
    database: session.database,
    projectId: session.manifest.id,
  ).getWeapon(weaponId);
});
