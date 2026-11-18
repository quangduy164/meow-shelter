import 'dart:math';
import 'night_cards.dart';

enum NightVariant {
  yardNormal(
      NightMap.backyard, 'Sân quen', 'Đèn và ánh trăng theo nhịp quen thuộc.'),
  yardSpread(NightMap.backyard, 'Đèn tản',
      'Đèn tách ra hai bên và cuối sân; ánh trăng bắt đầu từ bên trái.'),
  yardSweep(NightMap.backyard, 'Trăng quét',
      'Đèn xếp chéo; vệt trăng hẹp hơn và quét nhanh gấp rưỡi.'),
  marketNormal(NightMap.marketAlley, 'Chợ thường',
      'Xe qua đều, có khoảng yên tĩnh sau mỗi chuyến.'),
  marketRush(NightMap.marketAlley, 'Giờ cao điểm',
      'Xe qua theo nhịp ngắn dài xen kẽ, có báo trước mỗi chuyến.'),
  marketConvoy(NightMap.marketAlley, 'Xe từng cụm',
      'Hai chuyến gần nhau rồi nghỉ dài; xe đổi hướng sau mỗi chuyến.'),
  roofNormal(
      NightMap.rooftops, 'Cầu thẳng', 'Hai hàng cầu nối thẳng giữa ba mái.'),
  roofStaggered(NightMap.rooftops, 'Cầu so le',
      'Cầu hai phía lệch hàng; mèo phải đi chéo qua mái giữa.'),
  roofRepair(NightMap.rooftops, 'Cầu đang sửa',
      'Một cầu cần sửa 10 giây đầu đêm; cầu còn lại cùng phía vẫn dùng được.'),
  warehouseNormal(NightMap.warehouse, 'Ba lồng',
      'Ba lồng ngang sân, chốt cửa khi mèo vào trọn lồng.'),
  warehouseStaggered(NightMap.warehouse, 'Lồng so le',
      'Lồng đặt trước sau xen kẽ; chọn mồi để chia mèo ra từng lồng.'),
  warehouseService(NightMap.warehouse, 'Lồng bảo trì',
      'Một lồng cần chuẩn bị 8 giây đầu đêm; hai lồng khác dùng ngay.'),
  reedNormal(NightMap.reedGarden, 'Lau tĩnh',
      'Mười hai bụi lau, mèo đổi chỗ đều và để lại vết rung.'),
  reedWindy(NightMap.reedGarden, 'Gió lau',
      'Gió làm mèo đổi bụi nhanh hơn; hãy theo vết mới nhất.'),
  reedMist(NightMap.reedGarden, 'Sương lau',
      'Vết rung tan nhanh, nhưng cá dụ được mèo cách hai bụi.'),
  harborNormal(NightMap.harbor, 'Bến giữa',
      'Một bến ở luồng giữa; bẻ cửa nước để đưa bè về đó.'),
  harborTwin(NightMap.harbor, 'Hai bến',
      'Hai bến ở luồng trên và dưới, luồng giữa trôi ra mép.'),
  harborRocks(NightMap.harbor, 'Đá ngầm',
      'Đá chắn giữa sông; phải vòng qua luồng bên rồi quay lại.'),
  stationNormal(NightMap.station, 'Ga nhỏ',
      'Tàu ba toa, bảng điện báo trước biển toa chuyến sau.'),
  stationLong(
      NightMap.station, 'Tàu dài', 'Tàu bốn toa, có thêm vạch để xếp mèo.'),
  stationLate(
      NightMap.station, 'Đổi biển', 'Biển toa chỉ hiện khi tàu đang vào ga.'),
  clawNormal(NightMap.clawMachine, 'Máy chuẩn',
      'Một miệng thả bên trái, càng hạ thẳng.'),
  clawTwin(NightMap.clawMachine, 'Hai miệng',
      'Miệng thả ở cả hai bên; càng về miệng gần nhất.'),
  clawSwing(NightMap.clawMachine, 'Càng lắc',
      'Càng đung đưa khi hạ; canh lúc càng lắc về giữa.');

  const NightVariant(this.map, this.title, this.description);
  final NightMap map;
  final String title, description;
  static NightVariant choose(NightMap map, Random random,
      {NightVariant? previous}) {
    final choices = values.where((v) => v.map == map && v != previous).toList();
    return choices[random.nextInt(choices.length)];
  }

  static NightVariant normal(NightMap map) =>
      values.firstWhere((v) => v.map == map);
}

enum NightArrival {
  steady('Rải đều',
      'Mèo tới từng con, cách 3 giây; cứu sạch sân sẽ gọi đợt tới sớm.'),
  waves('Từng đợt',
      'Mỗi đợt tới tối đa 3 mèo, cách 9 giây; sân có thể đông hơn 1 mèo.'),
  surge('Dồn nhịp',
      'Một mèo tới trước, rồi đợt đông; các đợt nhỏ và đông xen kẽ.');

  const NightArrival(this.title, this.description);
  final String title, description;
}

/// Release budget is cumulative; field capacity is checked separately.
class NightArrivalPlan {
  NightArrivalPlan(
      {required this.style,
      required this.quota,
      required this.capacity,
      this.intro = false}) {
    released = min(
        quota,
        intro
            ? capacity
            : switch (style) {
                NightArrival.steady => 2,
                NightArrival.waves => 3,
                NightArrival.surge => 1,
              });
    remaining = _interval;
  }
  final NightArrival style;
  final int quota, capacity;
  final bool intro;
  late int released;
  late double remaining;
  int _wave = 0;
  int get fieldCap =>
      capacity + (!intro && style == NightArrival.waves ? 1 : 0);
  double get _interval => switch (style) {
        NightArrival.steady => 3,
        NightArrival.waves => 9,
        NightArrival.surge => _wave.isEven ? 6 : 3,
      };
  int get _batch => switch (style) {
        NightArrival.steady => 1,
        NightArrival.waves => 3,
        NightArrival.surge => _wave.isEven ? 3 : 1,
      };
  void update(double dt) {
    if (intro || released >= quota) return;
    remaining -= dt;
    while (remaining <= 0 && released < quota) {
      released = min(quota, released + _batch);
      _wave++;
      remaining += _interval;
    }
  }

  void onRescue(int rescued) {
    if (intro) released = min(quota, capacity + rescued);
  }

  void callSoon() {
    if (!intro && released < quota) remaining = min(remaining, 2);
  }
}
