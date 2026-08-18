import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/application/release_controller.dart';

void main() {
  group('ReleaseController', () {
    test('initial state has no active build', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(releaseProvider);
      expect(state.activeBuild, isNull);
      expect(state.isPublishing, isFalse);
    });

    test('startPublish sets isPublishing to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(releaseProvider.notifier).startPublish();
      expect(container.read(releaseProvider).isPublishing, isTrue);
    });

    test('finishPublish sets isPublishing to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(releaseProvider.notifier);
      notifier.startPublish();
      notifier.finishPublish();
      expect(container.read(releaseProvider).isPublishing, isFalse);
    });

    test(
      'toggleFollowing and toggleWatching update public project actions',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(releaseProvider.notifier);

        notifier.toggleFollowing();
        notifier.toggleWatching();

        final state = container.read(releaseProvider);
        expect(state.isFollowing, isTrue);
        expect(state.isWatching, isTrue);
      },
    );
  });
}
