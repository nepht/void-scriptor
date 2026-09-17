import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_belief_truth.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_reveal_links.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/myth_theology_culture_foreshadowing_integration.dart';

void main() {
  test('connects belief, truth, culture, symbols, idioms, and reveals', () {
    final result = const MythTheologyCultureForeshadowingIntegration().evaluate(
      belief: BeliefTruthRecord.validated(
        mythId: 'origin',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'public-origin',
          text: 'The first star sang the world awake',
        ),
        groupVariants: [
          GroupBeliefVariant.validated(
            groupId: 'tidekeepers',
            text: 'The star was a warning',
          ),
        ],
        truths: [
          HistoricalTruthClaim.validated(
            truthId: 'truth-1',
            statement: 'The star was a signal from the vanished makers',
            confidence: 0.9,
          ),
        ],
        sourceLinks: [
          BeliefSourceLink.validated(
            sourceId: 'chronicle-1',
            kind: 'chronicle',
          ),
        ],
      ),
      idiom: IdiomUsageProfile.validated(
        idiomId: 'star-song',
        cultures: [IdiomCultureRef.validated(cultureId: 'tidefolk')],
        contexts: [
          IdiomContextUsage.validated(
            context: SocialContext.ceremonial,
            register: IdiomRegister.ceremonial,
          ),
        ],
      ),
      reveals: RevealLinkRecord.validated(
        recordId: 'origin-thread',
        factId: 'truth-1',
        hiddenFact: 'The makers sent the signal',
        clueLinks: [
          ClueLink.validated(
            clueId: 'clue-1',
            kind: ClueKind.symbol,
            storyLink: 'scene-1',
            description: 'A star mark appears on a forbidden door',
            targetFactId: 'truth-1',
          ),
        ],
        symbols: [
          ForeshadowSymbol.validated(
            symbolId: 'star-mark',
            name: 'Star mark',
            appearances: ['scene-1'],
          ),
        ],
        revealPoints: [
          RevealPoint.validated(
            revealId: 'reveal-1',
            storyLink: 'scene-2',
            tick: 2,
          ),
        ],
      ),
    );

    expect(result.beliefVariantsResolved, isTrue);
    expect(result.historicalTruthResolved, isTrue);
    expect(result.cultureLinksResolved, isTrue);
    expect(result.symbolLinksResolved, isTrue);
    expect(result.idiomContextResolved, isTrue);
    expect(result.revealIntegrity, isTrue);
  });
}
