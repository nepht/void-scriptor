import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State untuk CinemaController.
class CinemaState {
  final String? activeShot;
  final bool isPlaying;
  final List<String> shots;

  const CinemaState({
    this.activeShot,
    this.isPlaying = false,
    this.shots = const [],
  });

  CinemaState copyWith({
    String? Function()? activeShot,
    bool? isPlaying,
    List<String>? shots,
  }) {
    return CinemaState(
      activeShot: activeShot != null ? activeShot() : this.activeShot,
      isPlaying: isPlaying ?? this.isPlaying,
      shots: shots ?? this.shots,
    );
  }
}

/// Controller untuk manajemen sinematik / cinema.
class CinemaController extends Notifier<CinemaState> {
  @override
  CinemaState build() {
    return const CinemaState();
  }

  void selectShot(String shotId) {
    state = state.copyWith(activeShot: () => shotId);
  }

  void togglePlayback() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }
}

final cinemaProvider = NotifierProvider<CinemaController, CinemaState>(
  CinemaController.new,
);
