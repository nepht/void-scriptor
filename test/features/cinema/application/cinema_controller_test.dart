import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/application/cinema_controller.dart';

void main() {
  group('CinemaController', () {
    test('initial state has no active shot and is not playing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(cinemaProvider);
      expect(state.activeShot, isNull);
      expect(state.isPlaying, isFalse);
    });

    test('selectShot updates active shot', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cinemaProvider.notifier).selectShot('shot_01');
      final state = container.read(cinemaProvider);
      expect(state.activeShot, 'shot_01');
    });

    test('togglePlayback flips isPlaying state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(cinemaProvider.notifier).togglePlayback();
      expect(container.read(cinemaProvider).isPlaying, isTrue);

      container.read(cinemaProvider.notifier).togglePlayback();
      expect(container.read(cinemaProvider).isPlaying, isFalse);
    });
  });
}
