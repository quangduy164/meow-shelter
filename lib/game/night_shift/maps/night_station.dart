import 'dart:math' as math;
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

enum TrainPhase { waiting, arriving, stopped, leaving }

enum TrainEvent { doorsOpen, departed }

/// Train timing and car signs. The scene owns cats, marks and rewards.
class StationLine {
  static const arriveSeconds = 2.4, leaveSeconds = 1.8;
  var phase = TrainPhase.waiting;
  var signs = <String?>[];
  var next = <String?>[];
  double timer = 0, gapSeconds = 7, stopSeconds = 5, walkSpeed = 1;
  int cars = 3, stage = 1;
  int? sharedCar;
  bool preview = true;

  void begin(NightRun run) {
    stage = (run.night - 1) ~/ NightRun.mapOrder.length + 1;
    cars = run.variant == NightVariant.stationLong ? 4 : 3;
    preview = run.variant != NightVariant.stationLate;
    gapSeconds =
        (stage >= 3 ? 5.5 : 7) + 3.0 * run.count(NightCard.earlyWhistle);
    stopSeconds = (stage >= 2 ? 3.8 : 5) + 1.5 * run.count(NightCard.longStop);
    walkSpeed = run.has(NightCard.porter) ? 1.5 : 1;
    sharedCar = run.has(NightCard.sharedCar) ? cars ~/ 2 : null;
    phase = TrainPhase.waiting;
    timer = gapSeconds;
    signs = List.filled(cars, null);
    next = List.filled(cars, null);
  }

  double markX(int car) => cars == 3 ? .25 + car * .25 : .2 + car * .2;

  static const _breeds = ['orange', 'black', 'himalaya', 'scottish', 'calico'];

  /// Plans the coming train while it is still away. Signs that still serve a
  /// waiting cat never flip, so a cat already moved stays right; free cars
  /// go to cats oldest first, so nobody is skipped twice in a row.
  void plan(List<String> waiting, math.Random random) {
    if (phase != TrainPhase.waiting && phase != TrainPhase.leaving) return;
    final plan = List<String?>.filled(cars, null);
    final want = [...waiting];
    bool free(int c) => c != sharedCar && plan[c] == null;
    for (var c = 0; c < cars; c++) {
      final old = c < next.length ? next[c] : null;
      if (free(c) && old != null && want.remove(old)) plan[c] = old;
    }
    for (var c = 0; c < cars; c++) {
      if (free(c) && want.isNotEmpty) plan[c] = want.removeAt(0);
    }
    for (var c = 0; c < cars; c++) {
      if (!free(c)) continue;
      final old = c < next.length ? next[c] : null;
      plan[c] = old ?? _breeds[random.nextInt(_breeds.length)];
    }
    next = plan;
  }

  /// What the post above [car] shows right now; null when hidden.
  String? shownSign(int car) => switch (phase) {
        TrainPhase.waiting || TrainPhase.leaving => preview ? next[car] : null,
        _ => signs[car],
      };

  /// Whether the next train has a car this breed can board.
  bool hasCarFor(String breed) => sharedCar != null || next.contains(breed);
  bool accepts(int car, String breed) =>
      phase == TrainPhase.stopped && (car == sharedCar || signs[car] == breed);

  /// 0 = parked at the platform, positive = still to the right, negative = gone left.
  double get offset => switch (phase) {
        TrainPhase.arriving =>
          math.pow(timer / arriveSeconds, 2).toDouble() * 1.1,
        TrainPhase.leaving =>
          -math.pow(1 - timer / leaveSeconds, 2).toDouble() * 1.1,
        TrainPhase.stopped => 0,
        TrainPhase.waiting => 1.2,
      };

  List<TrainEvent> update(double dt) {
    timer -= dt;
    if (timer > 0) return const [];
    switch (phase) {
      case TrainPhase.waiting:
        phase = TrainPhase.arriving;
        timer = arriveSeconds;
        signs = List.of(next);
        return const [];
      case TrainPhase.arriving:
        phase = TrainPhase.stopped;
        timer = stopSeconds;
        return const [TrainEvent.doorsOpen];
      case TrainPhase.stopped:
        phase = TrainPhase.leaving;
        timer = leaveSeconds;
        return const [];
      case TrainPhase.leaving:
        phase = TrainPhase.waiting;
        timer = gapSeconds;
        return const [TrainEvent.departed];
    }
  }
}
