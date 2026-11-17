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

  /// Signs for the coming train: each needed breed once, other cars decoys.
  void prepare(List<String> needed, math.Random random) {
    final pool = needed.toSet().take(cars).toList()..shuffle(random);
    const breeds = ['orange', 'black', 'himalaya', 'scottish', 'calico'];
    while (pool.length < cars) {
      pool.add(breeds[random.nextInt(breeds.length)]);
    }
    next = (pool..shuffle(random)).cast<String?>().toList();
  }

  /// A newcomer replaces one decoy sign, so earlier plans stay valid.
  void include(String breed, List<String> needed) {
    if (phase != TrainPhase.waiting || timer < 1.5 || next.contains(breed)) {
      return;
    }
    final decoy = [
      for (var i = 0; i < next.length; i++)
        if (next[i] == null || !needed.contains(next[i])) i
    ];
    if (decoy.isNotEmpty) next[decoy.first] = breed;
  }

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
  bool get signsShown => preview || phase != TrainPhase.waiting;

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
