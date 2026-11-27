import 'package:material_ui/material_ui.dart';
import '../design.dart';

/// Shared flat cream navigation for fishing selection and its destination panel.
class FishingMenuButton extends StatelessWidget {
  const FishingMenuButton(
      {super.key,
      required this.tooltip,
      required this.onPressed,
      required this.child,
      this.size = 44});
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
          style: IconButton.styleFrom(
              backgroundColor: DS.cream,
              foregroundColor: DS.ink,
              side: const BorderSide(color: Color(0xFFD8CEB8), width: 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: child));
}
