import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/weapon_repository_impl.dart';
import '../domain/weapon_model.dart';
import '../domain/weapon_workspace_data.dart';

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

/// Persisted child rows for the Weapon workspace detail cards
/// (vs-hunt-20260914-wardrobe-weapon WBUG-6). Null session or missing
/// weapon resolves to an empty [WeaponWorkspaceData] so the cards show
/// honest empty states instead of the previous hardcoded sample data.
final weaponWorkspaceDetailsProvider =
    FutureProvider.family<WeaponWorkspaceData, String>((ref, weaponId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return const WeaponWorkspaceData();
      return WeaponRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
      ).getWorkspaceData(weaponId);
    });
