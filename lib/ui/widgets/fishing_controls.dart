import 'package:flutter/material.dart';
import '../../fishing/fishing_controller.dart';
import 'fishing_action_button.dart';
import 'fishing_gauges.dart';

class FishingControls extends StatelessWidget {
  const FishingControls({super.key, required this.controller});
  final FishingController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
            width: 260,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _action(),
                if (controller.phase == FishingPhase.reeling)
                  Positioned(
                      right: 0,
                      top: 0,
                      child: IgnorePointer(
                          child: SizedBox(
                              width: 72,
                              height: 80,
                              child: FittedBox(
                                  child: FishingGauge(
                                      value: controller.tension,
                                      tension: true))))),
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
            busy: controller.phase == FishingPhase.casting,
            onPressed: controller.phase == FishingPhase.casting
                ? null
                : () => controller.cast(controller.spot)),
      };
}
