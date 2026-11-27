/// Cabin ship art: the moored pirate ship outside, and the two-room cabin
/// inside (layout in [FishingCabin], pictures cached and disposed here).
library;

import '../../fishing/fishing_place.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_cabin.dart';
import '../../fishing/fishing_cabin_chest.dart';
import '../../fishing/fishing_lighting.dart';
import 'fishing_art_kit.dart';
import 'fishing_action_button.dart';
import 'fishing_dialog_kit.dart';
import '../../fishing/fishing_river.dart';
import '../../game/constants.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'game_glyphs.dart';
import 'round_button.dart';
import '../../audio/game_audio.dart';

part 'fishing_cabin_ship_art.dart';
part 'fishing_cabin_room.dart';
part 'fishing_cabin_room_art.dart';

void _line(Canvas c, Offset a, Offset b, Color color, double w) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
void _rect(Canvas c, Rect r, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, const Radius.circular(4)),
    Paint()..color = color);
ui.Picture _record(void Function(Canvas) draw) {
  final r = ui.PictureRecorder();
  draw(Canvas(r));
  return r.endRecording();
}

Paint _fill(int color) => Paint()..color = Color(color);
Paint _stroke(int color, double width) => Paint()
  ..color = Color(color)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
