import 'package:material_ui/material_ui.dart';
import '../../game/night_shift/night_cards.dart';
import '../../game/night_shift/night_relics.dart';
import 'night_card_icons.dart';

const _relicArt = <NightRelic, NightCard>{
  NightRelic.embers: NightCard.hotCoins,
  NightRelic.bell: NightCard.extraLantern,
  NightRelic.moonPouch: NightCard.longNight,
  NightRelic.feastCharm: NightCard.lazyLunch,
  NightRelic.prism: NightCard.fullMoon,
};

class NightRelicIcon extends StatelessWidget {
  const NightRelicIcon(this.relic, {super.key, this.size = 40});
  final NightRelic relic;
  final double size;
  @override
  Widget build(BuildContext context) =>
      NightCardIcon(_relicArt[relic]!, size: size);
}
