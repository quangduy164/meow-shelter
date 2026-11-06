import 'package:flutter/material.dart';

import '../design.dart';

/// Gold circular icon button used for back / home / help in every mode.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: DS.gold,
        shape:
            const CircleBorder(side: BorderSide(color: DS.goldEdge, width: 3)),
        child:
            IconButton(icon: Icon(icon, color: DS.ink), onPressed: onPressed),
      );
}
