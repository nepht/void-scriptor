import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/planet_closeout_contract.dart';

void main() {
  test('closeout contract enumerates planet verification suites', () {
    const contract = PlanetCloseoutContract();
    expect(
      contract.requiredSuites,
      containsAll(<String>[
        'schema',
        'coordinates',
        'terrain',
        'climate',
        'streaming',
        'persistence',
        'scale',
      ]),
    );
    expect(contract.isCovered(contract.requiredSuites.toSet()), isTrue);
  });

  test('Kokuen and Crash Site remain preview-first named regions', () {
    final designer = PlanetScenarioCatalog.defaultCatalog();
    expect(designer.names, containsAll(<String>['Kokuen', 'Crash Site']));
    expect(designer.previewOnly, isTrue);
  });
}
