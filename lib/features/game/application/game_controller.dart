import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State untuk GameController.
///
/// Melacak level yang sedang aktif, status HUD, dan daftar game.
class GameState {
  final String? activeLevel;
  final List<String> levels;
  final bool isLoading;

  const GameState({
    this.activeLevel,
    this.levels = const [],
    this.isLoading = false,
  });

  GameState copyWith({
    String? Function()? activeLevel,
    List<String>? levels,
    bool? isLoading,
  }) {
    return GameState(
      activeLevel: activeLevel != null ? activeLevel() : this.activeLevel,
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller untuk manajemen game / level.
class GameController extends Notifier<GameState> {
  @override
  GameState build() {
    return const GameState();
  }

  void selectLevel(String levelId) {
    state = state.copyWith(activeLevel: () => levelId);
  }
}

final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);
