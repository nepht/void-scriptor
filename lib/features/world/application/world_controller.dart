import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorldState {
  final List<dynamic> simulations;
  final List<dynamic> events;

  const WorldState({this.simulations = const [], this.events = const []});

  WorldState copyWith({List<dynamic>? simulations, List<dynamic>? events}) {
    return WorldState(
      simulations: simulations ?? this.simulations,
      events: events ?? this.events,
    );
  }
}

class WorldController extends Notifier<WorldState> {
  @override
  WorldState build() {
    return const WorldState();
  }
}

final worldProvider = NotifierProvider<WorldController, WorldState>(
  WorldController.new,
);
