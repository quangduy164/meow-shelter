import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/cat_component.dart';
import '../components/shelter_zone_component.dart';

/// Chapter 6 storm: rain, water rising from the bottom of the yard, beds
/// that go under, and a rescue truck that parks on a timetable and takes any
/// cat while it waits.
class StormSystem {
  StormSystem({required this.floodTop, required this.riseSeconds});

  /// Highest the water gets (fraction of the field height from the top).
  final double floodTop;
  final double riseSeconds;
  Vector2 field = Vector2.zero();
  double time = 0;

  static const startTop = .97, truckPeriod = 24.0, truckOffset = 20.0;
  static const arrive = 2.5, park = 10.5, leave = 2.5;

  /// Water surface in pixels; rises smoothly then stops at [floodTop].
  double get waterTop {
    final k = (time / riseSeconds).clamp(0.0, 1.0);
    return (startTop + (floodTop - startTop) * k) * field.y;
  }

  bool inWater(Vector2 p) => p.y > waterTop;

  /// A bed counts as flooded once the water reaches its middle.
  bool flooded(ShelterZoneComponent bed) =>
      bed.position.y + bed.size.y * .55 > waterTop;

  double get _phase => (time + truckOffset) % truckPeriod;
  bool get truckParked => _phase >= arrive && _phase < arrive + park;
  double get truckLeavesIn =>
      truckParked ? arrive + park - _phase : 0;

  /// Truck bed area in pixels, sliding in from the left and out to the right.
  Rect get truckRect {
    final w = field.x * .26, h = field.y * .17;
    final parkX = field.x * .37;
    final p = _phase;
    double x;
    if (p < arrive) {
      x = -w + (parkX + w) * _ease(p / arrive);
    } else if (p < arrive + park) {
      x = parkX;
    } else if (p < arrive + park + leave) {
      x = parkX + (field.x - parkX) * _ease((p - arrive - park) / leave);
    } else {
      x = field.x + 10;
    }
    return Rect.fromLTWH(x, field.y * .16, w, h);
  }

  static double _ease(double k) => k * k * (3 - 2 * k);

  /// Whether [cat] was dropped onto the waiting truck.
  bool onTruck(CatComponent cat) =>
      truckParked && truckRect.inflate(10).contains(cat.center.toOffset());

  // ---------------------------------------------------------------- drawing

  /// Under the cats: flood water and the truck.
  void renderBack(Canvas canvas) {
    final top = waterTop;
    if (top < field.y) {
      final water = Rect.fromLTWH(0, top, field.x, field.y - top);
      canvas.drawRect(water, Paint()..color = const Color(0x8C3E6F97));
      final wave = Paint()
        ..color = const Color(0x99BFE0F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final path = Path()..moveTo(0, top);
      for (var x = 0.0; x <= field.x; x += 20) {
        path.lineTo(x, top + sin(time * 3 + x * .05) * 3);
      }
      canvas.drawPath(path, wave);
      // Rain rings on the water.
      for (var i = 0; i < 10; i++) {
        final k = (time * .8 + i * .37) % 1;
        final p = Offset((i * 157.0 + time * 13) % field.x,
            top + 12 + (i * 53.0) % max(1, field.y - top - 16));
        canvas.drawOval(
            Rect.fromCenter(center: p, width: 6 + 16 * k, height: 3 + 6 * k),
            Paint()
              ..color = Color.fromRGBO(220, 240, 255, .5 * (1 - k))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      }
    }
    _truck(canvas);
  }

  void _truck(Canvas canvas) {
    final r = truckRect;
    if (r.left > field.x || r.right < 0) return;
    canvas.drawOval(
        Rect.fromLTWH(r.left, r.bottom - 6, r.width, 14),
        Paint()..color = const Color(0x55101828));
    // Open cargo bed (the drop zone) with a red cross on the cab.
    final cab = Rect.fromLTWH(r.right - r.width * .28, r.top - 6,
        r.width * .28, r.height + 6);
    final bed = Rect.fromLTWH(r.left, r.top + 10, r.width * .74, r.height - 10);
    canvas.drawRRect(RRect.fromRectAndRadius(bed, const Radius.circular(8)),
        Paint()..color = const Color(0xFFF2EBDD));
    canvas.drawRRect(
        RRect.fromRectAndRadius(bed.deflate(6), const Radius.circular(6)),
        Paint()
          ..color =
              truckParked ? const Color(0xFFFFE9B8) : const Color(0xFFD9D2C4));
    canvas.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(10)),
        Paint()..color = const Color(0xFFF7F3EA));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cab.left + 6, cab.top + 6, cab.width - 12, 16),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF8FC3D9));
    final cross = cab.center + const Offset(0, 8);
    final red = Paint()..color = const Color(0xFFE0533E);
    canvas.drawRect(Rect.fromCenter(center: cross, width: 16, height: 5), red);
    canvas.drawRect(Rect.fromCenter(center: cross, width: 5, height: 16), red);
    // Flashing roof light.
    final flash = (time * 4).floor().isEven;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cab.center.dx, cab.top - 3), width: 18, height: 7),
            const Radius.circular(3)),
        Paint()
          ..color = flash ? const Color(0xFFE0533E) : const Color(0xFF5A9BE0));
    for (final x in [r.left + r.width * .18, r.right - r.width * .16]) {
      canvas.drawCircle(Offset(x, r.bottom), 9,
          Paint()..color = const Color(0xFF343C49));
      canvas.drawCircle(Offset(x, r.bottom), 4,
          Paint()..color = const Color(0xFFC6C6BB));
    }
    if (truckParked) {
      // Countdown blocks on the bed rail: the truck leaves when they run out.
      final left = (truckLeavesIn / park * 5).ceil();
      for (var i = 0; i < 5; i++) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bed.left + 8 + i * 13.0, bed.top - 8, 10, 6),
                const Radius.circular(2)),
            Paint()
              ..color = i < left
                  ? (left <= 1
                      ? const Color(0xFFE0533E)
                      : const Color(0xFF6BE07A))
                  : const Color(0x55000000));
      }
    }
  }

  /// Above the cats: rain, flooded-bed marks and the odd lightning flash.
  void renderFront(Canvas canvas, Iterable<ShelterZoneComponent> beds) {
    for (final bed in beds) {
      if (!flooded(bed)) continue;
      final r = bed.toRect();
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)),
          Paint()..color = const Color(0x993E6F97));
      final cross = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(r.center + const Offset(-12, -12),
          r.center + const Offset(12, 12), cross);
      canvas.drawLine(r.center + const Offset(12, -12),
          r.center + const Offset(-12, 12), cross);
    }
    final rain = Paint()
      ..color = const Color(0x66D6E8F5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final speed = 380 + (i % 4) * 60.0;
      final x = (i * 61.0 + time * 40) % (field.x + 40) - 20;
      final y = (i * 37.0 + time * speed) % (field.y + 40) - 20;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 14), rain);
    }
    final bolt = time % 17;
    if (bolt < .12 || (bolt > .22 && bolt < .3)) {
      canvas.drawRect(Offset.zero & Size(field.x, field.y),
          Paint()..color = const Color(0x55FFFFFF));
    }
  }
}

/// Draws [StormSystem] layers at a fixed depth in the component tree.
class StormLayer extends PositionComponent {
  StormLayer(this.paintLayer, {required int priority})
      : super(priority: priority);
  final void Function(Canvas canvas) paintLayer;

  @override
  void render(Canvas canvas) => paintLayer(canvas);
}
