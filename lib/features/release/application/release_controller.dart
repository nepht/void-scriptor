import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State untuk ReleaseController.
class ReleaseState {
  final String? activeBuild;
  final List<String> channels;
  final bool isPublishing;
  final bool isFollowing;
  final bool isWatching;

  const ReleaseState({
    this.activeBuild,
    this.channels = const [],
    this.isPublishing = false,
    this.isFollowing = false,
    this.isWatching = false,
  });

  ReleaseState copyWith({
    String? Function()? activeBuild,
    List<String>? channels,
    bool? isPublishing,
    bool? isFollowing,
    bool? isWatching,
  }) {
    return ReleaseState(
      activeBuild: activeBuild != null ? activeBuild() : this.activeBuild,
      channels: channels ?? this.channels,
      isPublishing: isPublishing ?? this.isPublishing,
      isFollowing: isFollowing ?? this.isFollowing,
      isWatching: isWatching ?? this.isWatching,
    );
  }
}

/// Controller untuk manajemen rilis / publishing.
class ReleaseController extends Notifier<ReleaseState> {
  @override
  ReleaseState build() {
    return const ReleaseState();
  }

  void selectChannel(String channel) {
    state = state.copyWith(channels: (state.channels.toList()..add(channel)));
  }

  void startPublish() {
    state = state.copyWith(isPublishing: true);
  }

  void finishPublish() {
    state = state.copyWith(isPublishing: false);
  }

  void toggleFollowing() {
    state = state.copyWith(isFollowing: !state.isFollowing);
  }

  void toggleWatching() {
    state = state.copyWith(isWatching: !state.isWatching);
  }
}

final releaseProvider = NotifierProvider<ReleaseController, ReleaseState>(
  ReleaseController.new,
);
