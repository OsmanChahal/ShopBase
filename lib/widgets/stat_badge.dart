import 'package:flutter/material.dart';

/// Reusable pill badge for stock levels ("High", "Low"), counts, and status labels.
class StatBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;

  const StatBadge({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory StatBadge.success({
    required String label,
    IconData? icon,
  }) {
    return StatBadge(
      label: label,
      icon: icon,
      backgroundColor: const Color(0xFFECFDF5),
      textColor: const Color(0xFF10B981),
    );
  }

  factory StatBadge.warning({
    required String label,
    IconData? icon,
  }) {
    return StatBadge(
      label: label,
      icon: icon,
      backgroundColor: const Color(0xFFFEF3C7),
      textColor: const Color(0xFFF59E0B),
    );
  }

  factory StatBadge.error({
    required String label,
    IconData? icon,
  }) {
    return StatBadge(
      label: label,
      icon: icon,
      backgroundColor: const Color(0xFFFEE2E2),
      textColor: const Color(0xFFEF4444),
    );
  }

  factory StatBadge.purple({
    required String label,
    IconData? icon,
  }) {
    return StatBadge(
      label: label,
      icon: icon,
      backgroundColor: const Color(0xFFF3E8FF),
      textColor: const Color(0xFF4B0F6B),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999), // Capsule/pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
