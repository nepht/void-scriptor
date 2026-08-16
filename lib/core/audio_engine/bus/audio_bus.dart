/// Audio bus (Step 34.7).
class AudioBus {
  const AudioBus({required this.name, this.gainDb = 0});

  final String name;
  final double gainDb;
}
