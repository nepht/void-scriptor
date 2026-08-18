import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';

void main() {
  group('PlatformController', () {
    test('initial state is ready with no active flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(platformProvider);
      expect(state.activeFlow, isNull);
      expect(state.isTourStarted, isFalse);
      expect(state.isDownloading, isFalse);
    });

    test('startTour updates tour state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(platformProvider.notifier).startTour();
      expect(container.read(platformProvider).isTourStarted, isTrue);
    });

    test('startDownload updates download state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(platformProvider.notifier).startDownload();
      expect(container.read(platformProvider).isDownloading, isTrue);
    });
  });
}
