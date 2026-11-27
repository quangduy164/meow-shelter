import 'fishing_menu_button.dart';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../online/fishing_world.dart';
import '../design.dart';
import 'paw_loader.dart';

/// A scenic postcard and clear guest action; reduces to the form with a keyboard.
class FishingWorldLobby extends StatelessWidget {
  const FishingWorldLobby(
      {super.key,
      required this.world,
      required this.code,
      required this.onChanged,
      this.enabled = true,
      this.error,
      this.onClose});
  final FishingWorld world;
  final TextEditingController code;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? error;
  final VoidCallback? onClose;
  static const _ink = Color(0xFF214F4C);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: world,
      builder: (context, _) => LayoutBuilder(builder: (context, box) {
            final height = box.maxHeight.isFinite ? box.maxHeight : 480.0;
            final wide = box.maxWidth >= 520 && height >= 270;
            final tight = height < 250;
            final photoHeight = math.min(138.0, math.max(0.0, height - 280));
            return Material(
                color: DS.cream,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                    padding: EdgeInsets.all(tight ? 10 : 18),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                              height: 32,
                              child: Row(children: [
                                Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                        color: _ink,
                                        borderRadius: BorderRadius.circular(9)),
                                    child: const Icon(Icons.explore_rounded,
                                        size: 20, color: DS.cream)),
                                const SizedBox(width: 9),
                                const Expanded(
                                    child: Text('HẸN NHAU TRÊN SÔNG',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: _ink))),
                                if (onClose != null)
                                  FishingMenuButton(
                                      tooltip: 'Đóng',
                                      onPressed: onClose,
                                      size: 32,
                                      child: const Icon(Icons.close_rounded,
                                          size: 20)),
                              ])),
                          SizedBox(height: tight ? 8 : 14),
                          if (wide)
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                      flex: 6,
                                      child: SizedBox(
                                          height: 204, child: _postcard())),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      flex: 5, child: _form(context, false)),
                                ])
                          else ...[
                            _form(context, tight),
                            if (!tight && photoHeight >= 70) ...[
                              const SizedBox(height: 12),
                              SizedBox(height: photoHeight, child: _postcard()),
                            ] else if (!tight) ...[
                              const SizedBox(height: 8),
                              _codeRow(false),
                            ],
                          ],
                        ])));
          }));

  Widget _form(BuildContext context, bool tight) {
    final hasCode = code.text.trim().isNotEmpty;
    final valid = !hasCode ||
        FishingWorld.validCode(FishingWorld.normalizeCode(code.text));
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!tight) ...[
            const Text('Ghé thăm bạn bè',
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 5),
            const Text('Cùng chèo thuyền, cùng đi câu.',
                style: TextStyle(fontSize: 12, color: DS.wood)),
            const SizedBox(height: 14),
          ],
          SizedBox(
              height: 46,
              child: TextField(
                  controller: code,
                  enabled: enabled,
                  onChanged: onChanged,
                  maxLength: 7,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (valid && enabled) {
                      FocusScope.of(context).unfocus();
                      onClose?.call();
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z2-9]'))
                  ],
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _ink),
                  decoration: InputDecoration(
                      hintText: 'Nhập mã ghé bạn',
                      counterText: '',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.people_alt_rounded,
                          color: _ink, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFB8CBC0))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFB8CBC0))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _ink, width: 2))))),
          const SizedBox(height: 10),
          SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                  onPressed: enabled && valid ? onClose : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD8CEB8)),
                      foregroundColor: _ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: Icon(
                      hasCode
                          ? Icons.arrow_forward_rounded
                          : Icons.home_rounded,
                      size: 19),
                  label: Text(hasCode ? 'DÙNG MÃ NÀY' : 'CHƠI MAP CỦA MÌNH',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900)))),
          if (!tight) ...[
            const SizedBox(height: 8),
            Text(
                error ??
                    (hasCode
                        ? 'Tiếp tục chọn mèo để sang map của bạn.'
                        : 'Hoặc nhập mã của bạn bè ở trên.'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: DS.wood)),
          ],
        ]);
  }

  Widget _postcard() => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/previews/fishing_island.png',
            fit: BoxFit.cover,
            semanticLabel: 'Đảo hải đăng và thuyền cướp biển trong game',
            filterQuality: FilterQuality.medium),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000B333D), Color(0xCC0B333D)],
                    stops: [.45, 1]))),
        Positioned(
            left: 12,
            right: 8,
            bottom: 8,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('THẾ GIỚI CỦA BẠN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFCEE8DC),
                          letterSpacing: 1)),
                  _codeRow(true),
                ])),
      ]));
  Widget _codeRow(bool dark) => Row(children: [
        Expanded(
            child: world.homeCode == null && world.busy
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: PawLoader(size: 22, color: dark ? DS.cream : _ink))
                : Text(world.homeCode ?? 'Chưa có mã',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: dark ? 19 : 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                        color: dark ? Colors.white : _ink))),
        Tooltip(
            message: world.homeCode == null
                ? (world.error ?? 'Lấy mã bản đồ')
                : 'Sao chép mã',
            child: IconButton(
                onPressed: !enabled || world.busy
                    ? null
                    : world.homeCode == null
                        ? world.prepare
                        : () => Clipboard.setData(
                            ClipboardData(text: world.homeCode!)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                style: IconButton.styleFrom(backgroundColor: DS.cream),
                icon: Icon(
                    world.homeCode == null
                        ? Icons.refresh_rounded
                        : Icons.copy_rounded,
                    size: 17,
                    color: _ink))),
      ]);
}
