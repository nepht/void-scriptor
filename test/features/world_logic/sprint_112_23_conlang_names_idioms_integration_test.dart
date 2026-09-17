import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_consistency.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_registry.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_collision.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';
import 'package:void_scriptor/features/world_logic/domain/conlang_names_idioms_integration.dart';

void main() {
  test(
    'connects phonotactics, culture, language, names, idioms, and era checks',
    () {
      final spec = PhonotacticsSpec.validated(
        id: 'void-spec',
        languageId: 'voidish',
        inventory: [
          SyllablePart.validated(symbol: 'a', slots: [SyllableSlot.nucleus]),
        ],
        patterns: [SyllablePattern.parse(id: 'v', template: 'V')],
        conlangLinks: [
          PhonotacticsConlangLink(
            targetLanguageId: 'ancestor-voidish',
            kind: ConlangLinkKind.primary,
          ),
        ],
      );
      final profile = CulturalNameProfile.validated(
        profileId: 'ash-profile',
        cultureId: 'ash-kin',
        languageId: 'voidish',
        era: NameEra.validated(
          eraId: 'era-1',
          label: 'First age',
          fromMarker: 'm001',
          toMarker: 'm100',
        ),
        entityTypes: {NameEntityType.person},
      );
      const idiomId = 'ember-saying';
      final usage = IdiomUsageCatalog.withProfiles([
        IdiomUsageProfile.validated(
          idiomId: idiomId,
          cultures: [IdiomCultureRef.validated(cultureId: 'ash-kin')],
          eras: [
            IdiomEraRange.validated(
              eraId: 'era-1',
              label: 'First age',
              fromMarker: 'm001',
              toMarker: 'm100',
            ),
          ],
        ),
      ]);
      final events = IdiomUsageLedger.withRecords(
        records: IdiomRegistry.withRecords([
          IdiomRecord.validated(
            idiomId: idiomId,
            type: IdiomType.saying,
            originalText: 'Ash remembers',
            literalTranslation: 'ash remembers',
            meaning: 'history persists',
            languageId: 'voidish',
          ),
        ]),
        events: [
          IdiomUsageEvent.validated(
            eventId: 'event-1',
            idiomId: idiomId,
            atMarker: 'm050',
            cultureId: 'ash-kin',
          ),
        ],
      );

      final result = const ConlangNamesIdiomsIntegration().evaluate(
        spec: spec,
        profile: profile,
        names: NameCheckReport.of([]),
        usage: usage,
        idioms: IdiomConsistencyReport.of([]),
        events: events,
      );

      expect(result.phonotacticReuse, isTrue);
      expect(result.cultureProfiles, isTrue);
      expect(result.languageLinks, isTrue);
      expect(result.nameCollisionFree, isTrue);
      expect(result.idiomUsage, isTrue);
      expect(result.anachronismChecks, isTrue);
      expect(result.isValid, isTrue);
    },
  );
}
