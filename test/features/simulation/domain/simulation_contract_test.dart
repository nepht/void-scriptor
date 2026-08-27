import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/simulation/domain/simulation_contract.dart';

void main() {
  group('explicit_inputs', () {
    test('contract menolak input kosong dan input tidak terdaftar', () {
      final contract = SimulationContract(
        seed: 42,
        precision: PrecisionPolicy(decimalPlaces: 3),
        units: UnitRegistry({'distance': 'km'}),
      );
      expect(() => contract.run(inputs: const {}), throwsArgumentError);
      expect(
        () => contract.run(inputs: const {'speed': 3}),
        throwsArgumentError,
      );
    });

    test('input registry menormalkan unit dan mengunci salinan input', () {
      final contract = SimulationContract(
        seed: 42,
        precision: PrecisionPolicy(decimalPlaces: 2),
        units: UnitRegistry({'distance': 'km', 'duration': 'hour'}),
      );
      final inputs = <String, double>{'distance': 10, 'duration': 2};
      final result = contract.run(inputs: inputs);
      inputs['distance'] = 999;
      expect(result.inputs['distance'], 10);
      expect(result.units['distance'], 'km');
    });
  });

  group('stable_seed and replayable_results', () {
    test('seed dan input sama menghasilkan hasil dan explanation sama', () {
      final first = _contract(
        seed: 7,
      ).run(inputs: const {'distance': 100, 'duration': 4});
      final second = _contract(
        seed: 7,
      ).run(inputs: const {'distance': 100, 'duration': 4});
      expect(second.value, first.value);
      expect(second.seed, 7);
      expect(second.explanation, first.explanation);
      expect(second.replayKey, first.replayKey);
    });

    test('seed berbeda dapat direplay terpisah dan key berbeda', () {
      final first = _contract(
        seed: 7,
      ).run(inputs: const {'distance': 100, 'duration': 4});
      final second = _contract(
        seed: 8,
      ).run(inputs: const {'distance': 100, 'duration': 4});
      expect(second.replayKey, isNot(first.replayKey));
    });
  });

  group('unit_registry and precision_policy', () {
    test('unit tidak boleh kosong dan hasil mengikuti precision policy', () {
      expect(() => UnitRegistry(const {'distance': ''}), throwsArgumentError);
      expect(() => PrecisionPolicy(decimalPlaces: -1), throwsArgumentError);
      final result = _contract(
        seed: 1,
      ).run(inputs: const {'distance': 10, 'duration': 3});
      expect(result.value, 3.33);
      expect(result.precision.decimalPlaces, 2);
    });
  });
}

SimulationContract _contract({required int seed}) => SimulationContract(
  seed: seed,
  precision: PrecisionPolicy(decimalPlaces: 2),
  units: UnitRegistry({'distance': 'km', 'duration': 'hour'}),
);
