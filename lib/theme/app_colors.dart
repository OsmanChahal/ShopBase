import 'package:flutter/material.dart';

/// Centralized color palette and gradient design tokens for ShopBase.
class AppColors {
  // === Brand Colors ===
  static const Color primaryPurple = Color(0xFF4B0F6B);
  static const Color primaryPurpleDark = Color(0xFF3B0764);
  static const Color primaryPurpleLight = Color(0xFF7C3AED);

  // === Gradients ===
  /// Hero Card Gradient (Purple -> Emerald Green)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4B0F6B), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Floating Action Button & Accent Action Gradient (Purple -> Pink/Magenta)
  static const LinearGradient fabGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Base Surfaces & Backgrounds ===
  static const Color screenBackground = Color(0xFFF5F5F7);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color baseWhite = Color(0xFFFFFFFF);

  // === Neutrals & Text ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color accentDark = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textGray = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);
  static const Color dividerGray = Color(0xFFF0F0F0);
  static const Color inactiveGray = Color(0xFF9CA3AF);

  // === Semantic Status Colors ===
  /// Emerald Green for high stock, in-stock badges, and profit metrics
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldGreenBg = Color(0xFFECFDF5);
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessBg = Color(0xFFECFDF5);

  /// Warning Amber/Orange for low-stock badges & warnings
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningOrangeBg = Color(0xFFFEF3C7);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0xFFFEF3C7);

  /// Error Red for delete actions, errors, and out-of-stock
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusErrorBg = Color(0xFFFEE2E2);
}
