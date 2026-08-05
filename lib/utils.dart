// Utility functions — v1.0.0

import 'dart:math';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

String generateId() => uuid.v4();

String formatDateTime(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

T clamp<T extends num>(T value, T min, T max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

double lerp(double a, double b, double t) {
  return a + (b - a) * t.clamp(0.0, 1.0);
}

List<T> chunkList<T>(List<T> list, int chunkSize) {
  final chunks = <T>[];
  for (var i = 0; i < list.length; i += chunkSize) {
    chunks.add(list.sublist(i, min(i + chunkSize, list.length)));
  }
  return chunks;
}
