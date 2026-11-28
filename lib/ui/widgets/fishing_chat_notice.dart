import 'package:material_ui/material_ui.dart';
import '../../online/fishing_chat.dart';

/// Short-lived text feed, independent of the map's frame ticker.
class FishingChatNotice extends StatelessWidget {
  const FishingChatNotice({super.key, required this.chat});
  final FishingChat chat;

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: AnimatedBuilder(
          animation: chat,
          builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final message in chat.notices)
                      Container(
                          key: ValueKey(message.id),
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xC2172E3B),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: '${message.name}: ',
                                    style: const TextStyle(
                                        color: Color(0xFF8DE8EF),
                                        fontWeight: FontWeight.w700)),
                                TextSpan(text: message.text),
                              ]),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.3))),
                  ])));
}
