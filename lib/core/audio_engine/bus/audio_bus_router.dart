/// A send from one bus to another (Step 34.9).
class BusSend {
  const BusSend({
    required this.source,
    required this.destination,
    required this.levelDb,
  });

  final String source;
  final String destination;
  final double levelDb;
}

/// Routes sends between buses (Step 34.9).
class AudioBusRouter {
  final List<BusSend> _sends = [];

  void addSend({
    required String source,
    required String destination,
    required double levelDb,
  }) {
    _sends.add(
      BusSend(source: source, destination: destination, levelDb: levelDb),
    );
  }

  List<BusSend> sendsFrom(String source) =>
      _sends.where((s) => s.source == source).toList();

  List<BusSend> get allSends => List.unmodifiable(_sends);
}
