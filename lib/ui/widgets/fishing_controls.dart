import 'package:flutter/material.dart';
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
            width: 80,
            height: 80,
            child: Stack(
              children: [
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
            tool: FishingTool.float,
            tooltip: 'Thả câu',
            primary: true,
            onPressed: controller.phase == FishingPhase.casting
                ? null
                : () => controller.cast(controller.spot)),
      };
}
