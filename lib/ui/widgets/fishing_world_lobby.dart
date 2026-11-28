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
      required this.onEnter,
      this.enabled = true,
      this.error,
      this.onClose});
  final FishingWorld world;
  final TextEditingController code;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onEnter;
  final String? error;
  final VoidCallback? onClose;
  static const _ink = Color(0xFF214F4C);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: world,
      builder: (context, _) => LayoutBuilder(builder: (context, box) {
            final height = box.maxHeight.isFinite ? box.maxHeight : 480.0;
            final padding = height < 200 ? 8.0 : 18.0;
            final width = box.maxWidth - padding * 2;
            final available = math.max(0.0, height - padding * 2);
            final header = available >= 150;
            final top = header ? 46.0 : 0.0;
            final room = available - top;
            final inline = room < 98;
            final title = room >= (error != null ? 176 : 150);
            final formHeight = inline
                ? 46.0
                : 98.0 + (title ? 37 : 0) + (title && error != null ? 38 : 0);
            final wide = width >= 480 && room >= 150;
            final photoWidth = wide ? (width - 14) * 6 / 11 : width;
            final photoHeight = wide
                ? math.min(180.0, room)
                : math.min(138.0, math.max(0.0, room - formHeight - 12));
            final showPhoto = photoHeight >= 70;
            final contentHeight = wide
                ? math.max(formHeight, photoHeight)
                : formHeight + (showPhoto ? photoHeight + 12 : 0);
            return Material(
                color: DS.cream,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: SizedBox(
                        height: top + contentHeight,
                        // Keep the input subtree mounted as keyboard insets animate.
                        child: Stack(children: [
                          if (header)
                            Positioned(
                                key: const ValueKey('room-header'),
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 32,
                                child: Row(children: [
                                  Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                          color: _ink,
                                          borderRadius:
                                              BorderRadius.circular(9)),
                                      child: const Icon(Icons.explore_rounded,
                                          size: 20, color: DS.cream)),
                                  const SizedBox(width: 9),
                                  const Expanded(
                                      child: Text('PHÒNG CHƠI',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: _ink))),
                                ])),
                          if (showPhoto)
                            Positioned(
                                key: const ValueKey('room-photo'),
                                left: 0,
                                top: wide ? top : top + formHeight + 12,
                                width: photoWidth,
                                height: photoHeight,
                                child: _postcard()),
                          Positioned(
                              key: const ValueKey('room-form'),
                              left: wide ? photoWidth + 14 : 0,
                              right: !header && onClose != null ? 40 : 0,
                              top: top +
                                  (wide ? (contentHeight - formHeight) / 2 : 0),
                              height: formHeight,
                              child:
                                  _form(context, title: title, inline: inline)),
                          if (onClose != null)
                            Positioned(
                                key: const ValueKey('room-close'),
                                right: 0,
                                top: header ? 0 : 7,
                                child: FishingMenuButton(
                                    tooltip: 'Đóng',
                                    onPressed: onClose,
                                    size: 32,
                                    child: const Icon(Icons.close_rounded,
                                        size: 20))),
                        ]))));
          }));

  Widget _form(BuildContext context,
      {required bool title, required bool inline}) {
    final hasCode = code.text.trim().isNotEmpty;
    final valid = !hasCode ||
        FishingWorld.validCode(FishingWorld.normalizeCode(code.text));
    final inputTop = title ? 37.0 : 0.0;
    return Stack(children: [
      if (title)
        const Positioned(
            key: ValueKey('room-form-title'),
            left: 0,
            right: 0,
            top: 0,
            child: Text('Vào phòng',
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900, color: _ink))),
      Positioned(
          key: const ValueKey('room-input'),
          left: 0,
          right: inline ? 130 : 0,
          top: inputTop,
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
                  onEnter();
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
                  hintText: 'Nhập mã phòng',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.people_alt_rounded,
                      color: _ink, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB8CBC0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB8CBC0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _ink, width: 2))))),
      Positioned(
          key: const ValueKey('room-confirm'),
          left: inline ? null : 0,
          right: 0,
          width: inline ? 120 : null,
          top: inline ? 2 : inputTop + 56,
          height: 42,
          child: ElevatedButton.icon(
              onPressed: enabled && valid ? onEnter : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD8CEB8)),
                  foregroundColor: _ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: Icon(
                  hasCode ? Icons.arrow_forward_rounded : Icons.home_rounded,
                  size: 19),
              label: Text(hasCode ? 'VÀO PHÒNG' : 'PHÒNG CỦA TÔI',
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900)))),
      if (title && error != null)
        Positioned(
            key: const ValueKey('room-error'),
            top: inputTop + 106,
            left: 0,
            right: 0,
            child: Text(error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: DS.wood))),
    ]);
  }

  Widget _postcard() => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/previews/fishing_island.webp',
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
                  const Text('MÃ PHÒNG CỦA BẠN',
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
                ? (world.error ?? 'Lấy mã phòng')
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
