import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/audio_engine/bus/audio_bus.dart';
import 'package:void_scriptor/core/audio_engine/bus/rms_meter.dart';
import 'package:void_scriptor/core/audio_engine/bus/audio_bus_router.dart';

void main() {
  test('AudioBus holds name and gain', () {
    const bus = AudioBus(name: 'music', gainDb: -6);
    expect(bus.name, 'music');
    expect(bus.gainDb, -6);
  });

  test('RmsMeter computes window RMS', () {
    const meter = RmsMeter();
    final samples = Float32List.fromList([0, 0, 2, 2]);
    final rms = meter.compute(samples);
    expect(rms, closeTo(1.4142135, 1e-4)); // sqrt((4+4)/4)
  });

  test('RmsMeter empty returns 0', () {
    const meter = RmsMeter();
    expect(meter.compute(Float32List(0)), 0);
  });

  test('AudioBusRouter routes sends', () {
    final router = AudioBusRouter();
    router.addSend(source: 'dialogue', destination: 'music', levelDb: -12);
    final sends = router.sendsFrom('dialogue');
    expect(sends, hasLength(1));
    expect(sends.first.destination, 'music');
    expect(sends.first.levelDb, -12);
  });
}
