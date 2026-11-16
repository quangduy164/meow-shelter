import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_relic_icon.dart';
import 'night_relic_stall_painter.dart';
import 'silver_token_icon.dart';

class NightRelicShop extends StatefulWidget {
  const NightRelicShop({super.key, required this.game});
  final NightGame game;

  @override
  State<NightRelicShop> createState() => _NightRelicShopState();
}

class _NightRelicShopState extends State<NightRelicShop> {
  NightRelic? _selectedRelic;
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final run = game.run!;
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: Color(0xD9111D30)),
        SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final compact = box.maxHeight < 420;
            final boardHeight = compact ? 330.0 : 410.0;
            final itemTop = compact ? 94.0 : 111.0;
            final itemHeight = compact ? 166.0 : 215.0;
            final bagTop = compact ? 271.0 : 355.0;
            return Padding(
              padding: const EdgeInsets.all(DS.spaceMd),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 740,
                        height: boardHeight,
                        child: Stack(children: [
                          const Positioned.fill(
                              child: CustomPaint(painter: RelicStallPainter())),
                          const Positioned(
                            left: 170,
                            right: 170,
                            top: 22,
                            child: Text('CỔ VẬT DƯỚI TRĂNG',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: DS.cream,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2)),
                          ),
                          Positioned(
                            top: compact ? 64 : 77,
                            left: 48,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xEE243953),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: const Color(0xFF9CBBD4))),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SilverTokenIcon(size: 25),
                                    const SizedBox(width: 5),
                                    Text('${run.silver} Nguyệt quang',
                                        style: const TextStyle(
                                            color: Color(0xFFE1F3FF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900)),
                                  ]),
                            ),
                          ),
                          Positioned(
                              top: compact ? 73 : 87,
                              right: 50,
                              child: const Text(
                                  'Giữ tên cổ vật để xem đầy đủ combo',
                                  style: TextStyle(
                                      color: Color(0xFFE4CFA3), fontSize: 10))),
                          Positioned(
                            top: itemTop,
                            left: 48,
                            right: 48,
                            height: itemHeight,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final relic in game.shopOffer)
                                    Expanded(
                                        child: _item(relic,
                                            compact: compact,
                                            height: itemHeight)),
                                ]),
                          ),
                          Positioned(
                            left: 42,
                            top: bagTop,
                            width: 450,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'TÚI CỔ VẬT  ${run.relics.length}/${NightRun.relicSlots}',
                                      style: const TextStyle(
                                          color: Color(0xFFFFD68E),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .7)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    for (var i = 0;
                                        i < NightRun.relicSlots;
                                        i++)
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 5),
                                          child: _inventorySlot(i),
                                        ),
                                      ),
                                  ]),
                                ]),
                          ),
                          Positioned(
                            top: bagTop + 3,
                            right: 42,
                            width: 172,
                            height: 38,
                            child: ElevatedButton.icon(
                              style: DS.primary,
                              onPressed: game.leaveNightShop,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                              label: Text('ĐI TIẾP · ĐÊM ${run.night + 1}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                          if (_selectedRelic != null &&
                              run.relics.contains(_selectedRelic)) ...[
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _selectedRelic = null),
                                child:
                                    const ColoredBox(color: Color(0x44000000)),
                              ),
                            ),
                            _relicPopover(_selectedRelic!,
                                boardHeight: boardHeight, bagTop: bagTop),
                          ],
                        ]),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 5),
                        const Text(
                            'Bán cổ vật nhận lại 50% giá mua · Mất hiệu ứng và combo của món đã bán',
                            style: TextStyle(
                                color: Color(0xFFB7C8DF), fontSize: 10)),
                      ],
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _inventorySlot(int index) {
    final relics = widget.game.run!.relics;
    if (index >= relics.length) {
      return Container(
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF513B32),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFB48B60)),
        ),
        child: const Center(
          child: Text('Ô trống',
              style: TextStyle(color: Color(0xFFE0C69D), fontSize: 10)),
        ),
      );
    }
    final relic = relics[index];
    return Tooltip(
      message: '${relic.title}: ${relic.details}',
      child: SizedBox(
        height: 30,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFD68E),
            backgroundColor: const Color(0xFF513B32),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFB48B60)),
            ),
          ),
          onPressed: () => setState(() => _selectedRelic = relic),
          child: Row(children: [
            NightRelicIcon(relic, size: 25),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(relic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9)),
                  const Text('Xem hiệu ứng',
                      style: TextStyle(fontSize: 9, color: Color(0xFFE0C69D))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _relicPopover(NightRelic relic,
      {required double boardHeight, required double bagTop}) {
    final index = widget.game.run!.relics.indexOf(relic);
    final anchor = 42.0 + index * 150 + 72.5;
    final left = (anchor - 150).clamp(24.0, 416.0);
    return Positioned(
      left: left,
      bottom: boardHeight - bagTop + 10,
      width: 300,
      height: 225,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: anchor - left - 6,
          bottom: -6,
          child: Transform.rotate(
              angle: .785398,
              child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: DS.cream,
                      border: Border(
                          right: BorderSide(color: DS.wood, width: 2),
                          bottom: BorderSide(color: DS.wood, width: 2))))),
        ),
        Material(
          color: DS.cream,
          elevation: 12,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DS.wood, width: 2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                NightRelicIcon(relic, size: 28),
                const SizedBox(width: 7),
                Expanded(child: Text(relic.title, style: DS.headingText)),
                SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Đóng thông tin',
                        onPressed: () => setState(() => _selectedRelic = null),
                        icon: const Icon(Icons.close_rounded, size: 18))),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(relic.details,
                      style:
                          DS.captionText.copyWith(color: DS.ink, height: 1.4)),
                ),
              ),
              const SizedBox(height: 7),
              const Text('Bán sẽ mất hiệu ứng và combo của món này.',
                  style: TextStyle(color: DS.soft, fontSize: 9)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  style: DS.primary,
                  onPressed: () {
                    if (widget.game.sellRelic(relic)) {
                      setState(() => _selectedRelic = null);
                    }
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sell_rounded, size: 16),
                        const SizedBox(width: 5),
                        Text('BÁN · +${relic.sellPrice}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4),
                        const SilverTokenIcon(size: 20),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _item(NightRelic relic,
      {required bool compact, required double height}) {
    final run = widget.game.run!;
    final bought = run.relics.contains(relic);
    final full = run.relics.length >= NightRun.relicSlots;
    final afford = run.silver >= relic.price;
    final combos = relic.comboCards.where(run.has).toList();
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
      decoration: BoxDecoration(
        color: bought ? const Color(0xFFDBE1CC) : const Color(0xFFF5E2B8),
        borderRadius: BorderRadius.circular(9),
        border:
            Border.all(color: combos.isNotEmpty ? DS.gold : DS.wood, width: 2),
      ),
      child: Column(children: [
        Opacity(
            opacity: bought ? .4 : 1,
            child: NightRelicIcon(relic, size: compact ? 30 : 40)),
        SizedBox(height: compact ? 2 : 4),
        Tooltip(
          message: relic.details,
          child: Text(relic.title,
              style: DS.bodyText.copyWith(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 3),
        Text(relic.description,
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: DS.captionText.copyWith(height: 1.15)),
        const SizedBox(height: 3),
        Text(
            combos.isNotEmpty
                ? '${combos.first.title}: ${relic.cardCombos[combos.first]}'
                : 'Ghép ${relic.comboCards.first.title}: ${relic.cardCombos.values.first}',
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: TextStyle(
                color: combos.isNotEmpty ? DS.success : DS.soft,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: compact ? 26 : 28,
          child: ElevatedButton(
            style: DS.primary,
            onPressed: bought || full || !afford
                ? null
                : () {
                    if (widget.game.buyRelic(relic)) setState(() {});
                  },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!bought && !full) ...[
                const SilverTokenIcon(size: 21),
                const SizedBox(width: 4),
              ],
              Text(
                  bought
                      ? 'ĐÃ MUA'
                      : full
                          ? 'TÚI ĐÃ ĐẦY'
                          : '${relic.price}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ]),
    );
  }
}
