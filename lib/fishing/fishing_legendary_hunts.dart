import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../collection/fish_species.dart';
import 'fishing_river.dart';

class FishingLegendarySign {
  const FishingLegendarySign(
      this.fish, this.position, this.age, this.ready, this.cue,
      {this.decoy = false,
      this.revealed = false,
      this.progress = 0,
      this.failed = false,
      this.heading = 0});
  final FishSpecies fish;
  final Offset position;
  final double age, heading;
  final bool ready, decoy, revealed, failed;
  final int progress;
  final String cue;
}

/// Personal skill trials; a correct attempt is deterministic, never a second luck roll.
class FishingLegendaryHunts {
  static const reach = 330.0, cooldown = 45.0;
  static const dragonInner = 150.0, dragonOuter = 260.0;
  final _until = <FishSpecies, double>{};
  List<FishingLegendarySign> signs = const [];
  double _follow = 0, _still = 0, _clock = 0, _noticeUntil = 0;
  String? _notice;
  String? get notice => _clock < _noticeUntil ? _notice : null;
  int? _dragonCycle;
  int _waves = 0;
  bool _waveFailed = false, _hasClock = false;

  static Offset nessieAt(double clock) {
    final x = 2600 + math.sin(clock * .12) * 330;
    return Offset(x, FishingRiver.center(x) + math.sin(clock * .21) * 65);
  }

  static Offset nessieDirection(double clock) {
    final d = nessieAt(clock + .1) - nessieAt(clock - .1);
    return d.distance < .001 ? const Offset(1, 0) : d / d.distance;
  }

  static Offset get moonAt =>
      Offset(FishingRiver.caveStart - 190, FishingRiver.caveCenterY + 55);
  static final moonPatches = [
    moonAt,
    moonAt + const Offset(170, 75),
    moonAt + const Offset(340, 0)
  ];
  static Offset get dragonAt {
    const x = FishingRiver.openSeaStart + 620;
    return Offset(x, FishingRiver.center(x) - 180);
  }

  static double waveDirection(int wave) =>
      -math.pi / 2 + wave * 2 * math.pi / 3;
  static double waveRadius(double age) => 90 + (age % 3) * 60;
  static bool inWave(Offset delta, int wave, double age) {
    if (delta.distance < .001) return false;
    return (waveRadius(age) - delta.distance).abs() < 22 &&
        math.cos(delta.direction - waveDirection(wave)) > .25;
  }

  void _tell(String text) {
    _notice = text;
    _noticeUntil = _clock + 4;
  }

  void _scareNessie() {
    _until[FishSpecies.catMew] = _clock + 18;
    _follow = 0;
    _tell('Nessie hoảng rồi! Lùi ra xa, đợi bóng quay lại.');
  }

  void update(double dt,
      {required double clock,
      required double hour,
      required Offset player,
      required bool moving,
      required bool enabled,
      double speed = 0}) {
    if (clock < _clock) {
      _until.clear();
      _dragonCycle = null;
      _noticeUntil = 0;
    }
    if (_hasClock && clock - _clock > .75) {
      _follow = 0;
      _still = 0;
      _dragonCycle = null;
    }
    _clock = clock;
    _hasClock = true;
    if (!enabled) {
      signs = const [];
      _follow = 0;
      _still = 0;
      _dragonCycle = null;
      return;
    }
    final nessie = nessieAt(clock), delta = player - nessie;
    if (clock >= (_until[FishSpecies.catMew] ?? 0)) {
      if (delta.distance < 125 ||
          (delta.distance < 360 && moving && speed > 150)) {
        _scareNessie();
      } else {
        final direction = nessieDirection(clock);
        final behind = delta.dx * direction.dx + delta.dy * direction.dy < -40;
        if (behind && delta.distance >= 145 && delta.distance < 310) {
          if (moving && speed >= 8) _follow = math.min(5, _follow + dt);
        } else {
          _follow = math.max(0, _follow - dt * 2);
        }
      }
    }
    final night = hour < 6 || hour >= 18;
    final moonIndex = (clock / 32).floor() % moonPatches.length;
    final realMoon = moonPatches[moonIndex];
    _still = night && !moving && (player - realMoon).distance < 360
        ? math.min(3, _still + dt)
        : 0;
    final n = clock % 24, m = clock % 16, d = clock % 18;
    final dragonDelta = player - dragonAt;
    final cycle = (clock / 18).floor();
    final inBand = dragonDelta.distance >= dragonInner &&
        dragonDelta.distance <= dragonOuter;
    if (dragonDelta.distance < 500) {
      if (_dragonCycle != cycle) {
        _dragonCycle = cycle;
        _waves = 0;
        _waveFailed = d >= 2.8;
      }
      if (!_waveFailed) {
        if (!inBand) {
          _waveFailed = true;
        } else if (d < 9 && inWave(dragonDelta, (d / 3).floor(), d)) {
          _waveFailed = true;
          _tell('Sóng tạt trúng thuyền! Đổi hướng né ở vòng sau.');
        }
        while (_waves < 3 && d >= _waves * 3 + 2.8 && !_waveFailed) {
          _waves++;
        }
      }
    } else {
      _dragonCycle = null;
      _waves = 0;
    }
    final surfaced = n >= 15 && n < 17.5;
    final moonBright = m >= 6 && m < 9;
    signs = [
      if (clock >= (_until[FishSpecies.catMew] ?? 0) &&
          FishingRiver.contains(nessie))
        FishingLegendarySign(
            FishSpecies.catMew,
            nessie,
            n,
            surfaced && _follow >= 5,
            surfaced && _follow >= 5
                ? 'Nessie ngoi lên! Canh đúng hướng bóng rồi thả câu'
                : 'Theo chậm phía sau bóng 5 giây; chờ ngoi lên mới thả câu',
            revealed: surfaced,
            heading: nessieDirection(clock).direction),
      if (night && clock >= (_until[FishSpecies.moonfish] ?? 0))
        for (var i = 0; i < moonPatches.length; i++)
          FishingLegendarySign(
              FishSpecies.moonfish,
              moonPatches[i],
              m,
              i == moonIndex && _still >= 3 && moonBright,
              'Tìm vệt có bóng cá; dừng 3 giây, thả lúc ánh bạc sáng',
              decoy: i != moonIndex,
              revealed: moonBright),
      if (clock >= (_until[FishSpecies.seaDragon] ?? 0))
        FishingLegendarySign(
            FishSpecies.seaDragon,
            dragonAt,
            d,
            _dragonCycle == cycle &&
                !_waveFailed &&
                _waves == 3 &&
                d >= 9 &&
                d < 12 &&
                inBand,
            _waveFailed
                ? 'Lỡ nhịp sóng! Giữ thuyền ở vành xoáy, đợi vòng mới'
                : _waves == 3 && d >= 9 && d < 12
                    ? 'Vượt ba đợt sóng! Hướng vào tâm xoáy và thả câu ngay'
                    : 'Giữ thuyền ở vành xoáy, lái tránh ba hướng sóng',
            progress: _waves,
            failed: _waveFailed),
    ];
  }

  FishingLegendarySign? nearby(Offset player) {
    FishingLegendarySign? best;
    var distance = 540.0;
    for (final sign in signs) {
      final d = (player - sign.position).distance;
      if (d < distance) {
        best = sign;
        distance = d;
      }
    }
    return best;
  }

  FishingLegendarySign? _aimed(
      Offset player, Offset direction, bool Function(Offset) canReach) {
    FishingLegendarySign? best;
    var alignment =
        .94; // About 20 degrees: fake reflections cannot snap to the real fish.
    for (final sign in signs) {
      final delta = sign.position - player, distance = delta.distance;
      if (distance < 110 || distance > reach || direction.distance < .001) {
        continue;
      }
      final dot = (delta.dx * direction.dx + delta.dy * direction.dy) /
          (distance * direction.distance);
      if (dot <= alignment ||
          !FishingRiver.regionAt(player.dx, y: player.dy)
              .fish
              .containsKey(sign.fish) ||
          !canReach(sign.position)) {
        continue;
      }
      best = sign;
      alignment = dot;
    }
    return best;
  }

  FishingLegendarySign? castTarget(Offset player, Offset direction,
      {required bool Function(Offset) canReach}) {
    final sign = _aimed(player, direction, canReach);
    return sign != null && sign.ready && !sign.decoy ? sign : null;
  }

  ({FishingLegendarySign? target, String? error}) attempt(
      Offset player, Offset direction,
      {required bool Function(Offset) canReach}) {
    final sign = _aimed(player, direction, canReach);
    if (sign == null) return (target: null, error: null);
    if (sign.ready && !sign.decoy) return (target: sign, error: null);
    final error = switch (sign.fish) {
      FishSpecies.catMew => 'Thả câu khi bóng đang lặn làm Nessie bỏ chạy',
      FishSpecies.moonfish => sign.decoy
          ? 'Chỉ là ánh trăng! Tìm vệt có bóng cá bên dưới'
          : 'Ánh bạc chưa đúng nhịp hoặc thuyền chưa đứng yên',
      _ => 'Chưa vượt đủ ba đợt sóng, Rồng biển chưa chịu cắn câu',
    };
    if (sign.fish == FishSpecies.catMew) _scareNessie();
    if (sign.fish == FishSpecies.moonfish) {
      _still = 0;
      _until[sign.fish] = _clock + 8;
    }
    if (sign.fish == FishSpecies.seaDragon) _waveFailed = true;
    signs = signs.where((s) => s.fish != sign.fish).toList();
    _tell(error);
    return (target: null, error: error);
  }

  void consume(FishingLegendarySign sign) {
    _until[sign.fish] = _clock + cooldown;
    signs = signs.where((s) => s.fish != sign.fish).toList();
    if (sign.fish == FishSpecies.catMew) _follow = 0;
    if (sign.fish == FishSpecies.moonfish) _still = 0;
  }
}
