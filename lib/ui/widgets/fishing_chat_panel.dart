import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../online/fishing_chat.dart';
import '../design.dart';
import 'fishing_menu_button.dart';
import 'game_surfaces.dart';

class FishingChatButton extends StatelessWidget {
  const FishingChatButton(
      {super.key, required this.chat, required this.onPressed});
  final FishingChat chat;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: chat,
      builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
            FishingMenuButton(
                tooltip: 'Trò chuyện trong phòng',
                onPressed: onPressed,
                size: 36,
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 20)),
            if (chat.unread > 0)
              Positioned(
                  right: -3,
                  top: -3,
                  child: IgnorePointer(
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                              color: DS.goldEdge,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('${chat.unread}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800))))),
          ]));
}

class FishingChatPanel extends StatefulWidget {
  const FishingChatPanel(
      {super.key,
      required this.chat,
      required this.name,
      required this.onReconnect});
  final FishingChat chat;
  final String Function() name;
  final Future<void> Function() onReconnect;
  @override
  State<FishingChatPanel> createState() => _FishingChatPanelState();
}

class _FishingChatPanelState extends State<FishingChatPanel> {
  final _text = TextEditingController();
  bool _reconnecting = false, _boundToRoom = false, _closing = false;
  int _tab = 0;
  static const _titles = ['Câu nói nhanh', 'Biểu cảm', 'Lịch sử'];
  static const _icons = [
    Icons.chat_bubble_outline_rounded,
    Icons.emoji_emotions_outlined,
    Icons.history_rounded
  ];

  @override
  void initState() {
    super.initState();
    _boundToRoom = widget.chat.uid != null;
    widget.chat.addListener(_roomChanged);
    widget.chat.setReading(true);
  }

  @override
  void dispose() {
    widget.chat.removeListener(_roomChanged);
    widget.chat.setReading(false);
    _text.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _roomChanged() {
    if (widget.chat.uid != null) {
      _boundToRoom = true;
    } else if (_boundToRoom && !_closing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) _close();
      });
    }
  }

  Future<void> _send([String? quick]) async {
    if (_closing) return;
    FocusScope.of(context).unfocus();
    if (await widget.chat.send(quick ?? _text.text, name: widget.name()) &&
        mounted) {
      _close();
    }
  }

  Future<void> _reconnect() async {
    setState(() => _reconnecting = true);
    try {
      await widget.onReconnect();
    } finally {
      if (mounted) setState(() => _reconnecting = false);
    }
  }

  Widget _content(FishingChat chat) {
    final enabled = chat.ready && !chat.sending;
    if (_tab == 0) {
      return ListView(padding: const EdgeInsets.all(8), children: [
        for (final text in FishingChat.quickMessages)
          Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                  color: const Color(0x193DB7C5),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: enabled ? () => _send(text) : null,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 8),
                          child: Text(text,
                              style: TextStyle(
                                  color:
                                      enabled ? Colors.white : Colors.white38,
                                  fontSize: 11))))))
      ]);
    }
    if (_tab == 1) {
      return GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(8),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.1,
          children: [
            for (final emote in FishingChat.emotes)
              Material(
                  color: const Color(0x183DB7C5),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: enabled ? () => _send(emote) : null,
                      child: Center(
                          child: Text(emote,
                              style: const TextStyle(fontSize: 24)))))
          ]);
    }
    final messages = chat.messages;
    if (messages.isEmpty) {
      return const Center(
          child: Text('Chưa có tin nhắn',
              style: TextStyle(color: Colors.white60, fontSize: 11)));
    }
    return ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final m = messages[messages.length - 1 - index];
          return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${m.uid == chat.uid ? 'Bạn' : m.name}: ',
                        style: TextStyle(
                            color: m.uid == chat.uid
                                ? const Color(0xFFFFD67B)
                                : const Color(0xFF78D8E6),
                            fontWeight: FontWeight.w700)),
                    TextSpan(text: m.text),
                  ]),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, height: 1.35)));
        });
  }

  @override
  Widget build(BuildContext context) => GameDialog(
      maxWidth: 260,
      alignment: Alignment.centerRight,
      backgroundColor: const Color(0xED172E3B),
      padding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
      child: LayoutBuilder(
        builder: (context, box) => SizedBox(
            width: 260,
            height: math.min(240, box.maxHeight),
            child: AnimatedBuilder(
                animation: widget.chat,
                builder: (context, _) {
                  final chat = widget.chat;
                  final compact = box.maxHeight < 200;
                  return Column(children: [
                    Expanded(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          SizedBox(
                              width: 40,
                              child: SingleChildScrollView(
                                  child: Column(children: [
                                for (var i = 0; i < _icons.length; i++)
                                  Tooltip(
                                      message: _titles[i],
                                      child: Material(
                                          color: _tab == i
                                              ? const Color(0x333DB7C5)
                                              : Colors.transparent,
                                          child: InkWell(
                                              onTap: () =>
                                                  setState(() => _tab = i),
                                              child: SizedBox(
                                                  width: 40,
                                                  height: 44,
                                                  child: Icon(_icons[i],
                                                      size: 20,
                                                      color: _tab == i
                                                          ? const Color(
                                                              0xFF8DE8EF)
                                                          : Colors.white54)))))
                              ]))),
                          const VerticalDivider(
                              width: 1, color: Color(0x334B92A5)),
                          Expanded(
                              child: Column(children: [
                            if (!compact)
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 8, 10, 4),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(_titles[_tab],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)))),
                            Expanded(child: _content(chat)),
                          ])),
                        ])),
                    if (chat.error != null && box.maxHeight >= 140)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(chat.error!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFFFBC9E), fontSize: 11))),
                    if (!chat.ready && !compact)
                      TextButton(
                          onPressed: _reconnecting || chat.connecting
                              ? null
                              : _reconnect,
                          child: Text(
                              _reconnecting || chat.connecting
                                  ? 'Đang kết nối chat…'
                                  : 'Thử kết nối lại',
                              style:
                                  const TextStyle(color: Color(0xFF8DE8EF)))),
                    Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                            key: const ValueKey('chat-composer'),
                            children: [
                              Expanded(
                                  child: TextField(
                                      key: const ValueKey('fishing-chat-input'),
                                      controller: _text,
                                      enabled: chat.ready,
                                      textInputAction: TextInputAction.send,
                                      inputFormatters: [
                                        TextInputFormatter.withFunction(
                                            (old, next) =>
                                                next.text.runes.length <= 120
                                                    ? next
                                                    : old)
                                      ],
                                      onSubmitted: (_) => _send(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                      decoration: InputDecoration(
                                          hintText: chat.ready
                                              ? 'Nhập tin nhắn…'
                                              : 'Chat chưa sẵn sàng',
                                          hintStyle: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10),
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0x4410202A),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 9, vertical: 10),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                  color: Color(0x445B9BAB)))))),
                              const SizedBox(width: 5),
                              FishingMenuButton(
                                  tooltip: 'Gửi tin nhắn',
                                  size: 36,
                                  onPressed: chat.ready && !chat.sending
                                      ? () => _send()
                                      : null,
                                  child: Icon(
                                      chat.sending
                                          ? Icons.more_horiz_rounded
                                          : Icons.send_rounded,
                                      size: 19)),
                            ])),
                  ]);
                })),
      ));
}
