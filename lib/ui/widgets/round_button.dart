import 'package:flutter/material.dart';

import '../design.dart';

/// Gold circular icon button used for back / home / help in every mode.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  // Fixed size, so a parent with tight constraints (e.g. a Stack with
  // StackFit.expand) can never stretch it across the screen.
  Widget build(BuildContext context) => UnconstrainedBox(
        child: SizedBox.square(
          dimension: 48,
          child: Material(
            color: DS.gold,
            shape: const CircleBorder(
                side: BorderSide(color: DS.goldEdge, width: 3)),
            child: IconButton(
                icon: Icon(icon, color: DS.ink), onPressed: onPressed),
          ),
        ),
      );
}
