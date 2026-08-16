import 'package:flutter/material.dart';

/// RMS meter panel (Step 34.16).
class AudioMeterPanel extends StatelessWidget {
  const AudioMeterPanel({super.key, required this.rmsDb, required this.gainDb});

  final double rmsDb;
  final double gainDb;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audio Meter', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('RMS: ${rmsDb.toStringAsFixed(1)} dB'),
        Text('Gain: ${gainDb.toStringAsFixed(1)} dB'),
      ],
    );
  }
}
