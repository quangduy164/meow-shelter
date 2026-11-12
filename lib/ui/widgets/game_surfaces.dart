import 'package:flutter/material.dart';

import '../design.dart';

Future<T?> showGameDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) =>
    showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: DS.scrim,
    );

/// A raised card or an inset section; layout remains owned by each screen.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.inset = false,
    this.padding = const EdgeInsets.all(DS.spaceLg),
  });

  final Widget child;
  final bool inset;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: inset ? DS.insetCard : DS.card.copyWith(color: DS.cream),
        child: Padding(padding: padding, child: child),
      );
}

/// Shared modal shell; it never adds a hidden scroll view or scales controls.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.child,
    this.maxWidth = DS.dialogWidth,
    this.padding = const EdgeInsets.all(DS.spaceLg),
    this.insetPadding = const EdgeInsets.all(DS.spaceLg),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: insetPadding,
        backgroundColor: DS.cream,
        shape: DS.dialogShape,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}

class GameDialogHeader extends StatelessWidget {
  const GameDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.icon,
    this.closeTooltip = 'Đóng',
  });

  final String title, closeTooltip;
  final VoidCallback onClose;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (icon != null) ...[
          Icon(icon, color: DS.goldEdge, size: DS.iconLg),
          const SizedBox(width: DS.spaceSm),
        ],
        Expanded(child: Text(title, style: DS.title)),
        IconButton(
          tooltip: closeTooltip,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: DS.iconMd),
        ),
      ]);
}

class GameStat extends StatelessWidget {
  const GameStat(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  final Widget icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => GamePanel(
        inset: true,
        padding: const EdgeInsets.all(DS.spaceSm),
        child: Row(children: [
          icon,
          const SizedBox(width: DS.spaceSm),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DS.valueText),
              const SizedBox(height: DS.space2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DS.captionText),
            ],
          )),
        ]),
      );
}

class GameBadge extends StatelessWidget {
  const GameBadge(this.label, {super.key, this.color = DS.soft});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DS.spaceSm, vertical: DS.spaceXs),
        decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(DS.radiusSm)),
        child: Text(label,
            style: DS.microText
                .copyWith(color: color, fontWeight: FontWeight.w900)),
      );
}
