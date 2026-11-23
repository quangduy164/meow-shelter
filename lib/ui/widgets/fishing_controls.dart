import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import 'fishing_action_button.dart';

class FishingControls extends StatelessWidget {
  const FishingControls({super.key, required this.controller});
  final FishingController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
            width: 144,
            height: 80,
            child: Stack(
              children: [
                if (controller.canSail)
                  Positioned(
                      left: 0,
                      top: 12,
                      child: Column(children: [
                        FishingActionButton(
                            tool: FishingTool.bait,
                            tooltip: controller.useLegendaryBait
                                ? 'Mồi huyền thoại: BẬT · Chạm để tắt'
                                : 'Mồi huyền thoại: TẮT · Chạm để bật',
                            active: controller.useLegendaryBait,
                            onPressed: controller.preparingCast
                                ? null
                                : controller.toggleLegendaryBait),
                        Text('${controller.collection.legendaryBait}',
                            style: TextStyle(
                                color: controller.useLegendaryBait
                                    ? const Color(0xFFFFDE85)
                                    : const Color(0xFFFFF4DA),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                      color: Color(0xFF493F30), blurRadius: 3)
                                ])),
                      ])),
                Align(alignment: Alignment.centerRight, child: _action()),
              ],
            )));
  }

  Widget _action() => switch (controller.phase) {
        FishingPhase.reeling => FishingActionButton(
            tool: FishingTool.reel,
            tooltip: 'Giữ để kéo cá, thả để nới dây',
            primary: true,
            active: controller.pulling,
            rotation: controller.pulling ? controller.clock * 6 : 0,
            onHoldChanged: controller.setPulling),
        FishingPhase.waiting || FishingPhase.bite => FishingActionButton(
            tool: FishingTool.hook,
            tooltip: 'Giật cần',
            primary: true,
            alert: controller.phase == FishingPhase.bite,
            onPressed: controller.hook),
        FishingPhase.saving => FishingActionButton(
            tool: FishingTool.save,
            tooltip: controller.error == null ? 'Đang lưu cá' : 'Lưu lại',
            primary: true,
            busy: controller.error == null,
            onPressed: controller.error == null ? null : controller.retrySave),
        _ => FishingActionButton(
            tool: FishingTool.rod,
            tooltip: 'Thả câu tại đây',
            primary: true,
            busy: controller.preparingCast,
            onPressed: controller.preparingCast ||
                    controller.phase == FishingPhase.casting
                ? null
                : controller.castHere),
      };
}
