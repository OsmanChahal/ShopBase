import 'package:flutter/material.dart';

/// Colors and shadows taken from the inventory / transfer HTML designs.
class InvDesign {
  static const bg = Color(0xFFF8F9FC);
  static const title = Color(0xFF2F104F);
  static const plum = Color(0xFF4A1D7A);
  static const accent = Color(0xFF8A3FFC);
  static const green = Color(0xFF05C168);
  static const orange = Color(0xFFFA7C17);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate900 = Color(0xFF0F172A);
  static const amber600 = Color(0xFFD97706);

  static const cardShadow = [
    BoxShadow(color: Color(0x0D3C285A), blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const fabGradient = LinearGradient(
    colors: [Color(0xFFFF458A), Color(0xFFB82BE2), Color(0xFF6E2FF7)],
    stops: [0, 0.55, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const brandGradient = LinearGradient(
    colors: [Color(0xFF3B145E), Color(0xFF551D85)],
  );
}
