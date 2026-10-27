import 'package:flutter/material.dart';

class TitlePlaque extends StatelessWidget {
  const TitlePlaque({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFDF81), Color(0xFFBD6D25)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6E3C16), width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: const Text('CHỌN MÀN',
          style: TextStyle(
              color: Color(0xFF643613),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2)),
    );
  }
}
