import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/studio_closeout_contract.dart';

void main() {
  test(
    'closeout contract covers organization, delegation, governance, and failure',
    () {
      const contract = StudioCloseoutContract();
      expect(
        contract.requiredSuites,
        containsAll(<String>[
          'organization',
          'delegation',
          'governance',
          'failure',
          'adversarial',
        ]),
      );
      expect(
        contract.isCovered({
          'organization',
          'delegation',
          'governance',
          'failure',
          'adversarial',
        }),
        isTrue,
      );
    },
  );

  test('Qowner episode template keeps departments and human gate', () {
    final episode = QownerEpisodeTemplate.create();
    expect(
      episode.departments,
      containsAll(<String>[
        'Character',
        'Environment',
        'Cinematography',
        'Storyboard',
        'QC',
      ]),
    );
    expect(episode.requiresHumanGate, isTrue);
    expect(episode.humanGate('publish'), isFalse);
    episode.approve('publish');
    expect(episode.humanGate('publish'), isTrue);
  });
}
