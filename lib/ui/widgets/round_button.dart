import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFFCCB59),
        shape: const CircleBorder(
            side: BorderSide(color: Color(0xFF774016), width: 3)),
        child: IconButton(
            icon: Icon(icon, color: const Color(0xFF643613)),
            onPressed: onPressed),
      );
}
