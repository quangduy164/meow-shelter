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
                      Padding(
                          key: ValueKey(message.id),
                          padding: const EdgeInsets.only(bottom: 6),
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
                                  height: 1.3,
                                  shadows: [
                                    Shadow(
                                        color: Color(0xCC14232C),
                                        blurRadius: 3,
                                        offset: Offset(0, 1))
                                  ]))),
                  ])));
}
