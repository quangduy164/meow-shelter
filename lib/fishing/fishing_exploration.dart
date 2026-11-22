import 'package:flutter/painting.dart';
import 'fishing_river.dart';

/// Minimap fog: which 200-unit cells the cat has seen. Saved with the trip.
class FishingExploration {
  static const cell = 200.0;
  static final columns = (FishingRiver.length / cell).ceil();
  static final rows = (FishingRiver.height / cell).ceil();
  static const _reach = 3;

  final cells = List.filled(columns * rows, false);

  /// Set when a new cell opens; the trip saver clears it after saving.
  bool changed = false;

  bool isExplored(int column, int row) => cells[row * columns + column];

  /// Restores saved cells row by row, so saves made before the world grew
  /// longer keep their explored area; other sizes are ignored.
  void load(List<bool> saved) {
    if (saved.isEmpty || saved.length % rows != 0) return;
    final savedColumns = saved.length ~/ rows;
    final copy = savedColumns < columns ? savedColumns : columns;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < copy; c++) {
        cells[r * columns + c] = saved[r * savedColumns + c];
      }
    }
  }

  /// Opens a rough circle of cells around [p].
  void reveal(Offset p, {int reach = _reach}) {
    final c0 = (p.dx / cell).floor(), r0 = (p.dy / cell).floor();
    for (var r = r0 - reach; r <= r0 + reach; r++) {
      for (var c = c0 - reach; c <= c0 + reach; c++) {
        if (c < 0 || r < 0 || c >= columns || r >= rows) continue;
        if ((c - c0) * (c - c0) + (r - r0) * (r - r0) > reach * reach + 1) {
          continue;
        }
        final i = r * columns + c;
        if (!cells[i]) {
          cells[i] = true;
          changed = true;
        }
      }
    }
  }
}
