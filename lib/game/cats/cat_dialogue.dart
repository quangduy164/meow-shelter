import 'dart:math';
import 'cat_state.dart';

class CatDialogue {
  CatDialogue({Random? random}) : _random = random ?? Random();
  final Random _random;
  String? text;
  double _remaining = 0, _cooldown = 0;

  void update(double dt) {
    _cooldown = max(0, _cooldown - dt);
    _remaining = max(0, _remaining - dt);
    if (_remaining == 0) text = null;
  }

  void react(CatState action) {
    final lines = switch (action) {
      CatState.dashEscape => const [
          'Đố anh bắt được em!',
          'Nhanh tay lên nào!',
          'Bắt hụt rồi nha!'
        ],
      CatState.vanish => const ['Ú òa! Em đâu rồi?', 'Thoắt ẩn, thoắt hiện!'],
      CatState.dragged => const [
          'Nhẹ tay, em chưa mua bảo hiểm!',
          'Đi nhờ một đoạn nha!'
        ],
      CatState.dropWrong => const [
          'Nhầm nhà rồi sen ơi!',
          'Ổ này chưa hợp phong thủy!'
        ],
      CatState.celebrate => const ['Chốt ổ này nha!', 'Ở đây có bao ăn không?'],
      _ => const <String>[],
    };
    if (lines.isEmpty) return;
    text = null;
    if (_cooldown > 0 || _random.nextDouble() >= .55) return;
    text = lines[_random.nextInt(lines.length)];
    _remaining = 2.4;
    _cooldown = 8 + _random.nextDouble() * 5;
  }
}
