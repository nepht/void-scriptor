/// Sprint 112.23 — integrasi konlang, nama, dan idiom.
///
/// Boundary domain-only ini menyatukan kontrak fonotaktik, profil budaya,
/// laporan nama, profil pemakaian idiom, dan pemeriksaan era. Ia tidak
/// membaca persistence, UI, jaringan, wall-clock, atau random.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_consistency.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_collision.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

class ConlangNamesIdiomsResult {
  const ConlangNamesIdiomsResult({
    required this.phonotacticReuse,
    required this.cultureProfiles,
    required this.languageLinks,
    required this.nameCollisionFree,
    required this.idiomUsage,
    required this.anachronismChecks,
  });

  final bool phonotacticReuse;
  final bool cultureProfiles;
  final bool languageLinks;
  final bool nameCollisionFree;
  final bool idiomUsage;
  final bool anachronismChecks;

  bool get isValid =>
      phonotacticReuse &&
      cultureProfiles &&
      languageLinks &&
      nameCollisionFree &&
      idiomUsage &&
      anachronismChecks;
}

class ConlangNamesIdiomsIntegration {
  const ConlangNamesIdiomsIntegration();

  ConlangNamesIdiomsResult evaluate({
    required PhonotacticsSpec spec,
    required CulturalNameProfile profile,
    required NameCheckReport names,
    required IdiomUsageCatalog usage,
    required IdiomConsistencyReport idioms,
    required IdiomUsageLedger events,
  }) {
    final linkedLanguages = spec.conlangLinks
        .map((link) => link.targetLanguageId)
        .toSet();
    final languageLinks =
        linkedLanguages.isNotEmpty &&
        spec.conlangLinks.any((link) => link.kind == ConlangLinkKind.primary);
    final profileMatchesLanguage = profile.languageId == spec.languageId;
    final profileSupportsNamedPeople = profile.supportsEntityType(
      NameEntityType.person,
    );
    final profilesResolve = usage.profiles.every(
      (item) => item.idiomId.trim().isNotEmpty,
    );
    final eventsResolveProfiles = events.events.every(
      (event) => usage.profileFor(event.idiomId) != null,
    );

    return ConlangNamesIdiomsResult(
      phonotacticReuse: spec.patterns.isNotEmpty && spec.inventory.isNotEmpty,
      cultureProfiles: profileMatchesLanguage && profileSupportsNamedPeople,
      languageLinks: languageLinks,
      nameCollisionFree: !names.hasBlockingIssues,
      idiomUsage: profilesResolve && eventsResolveProfiles,
      anachronismChecks: !idioms.hasIssues,
    );
  }
}
