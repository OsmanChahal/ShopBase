import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable metric card supporting both hero gradient style and flat surface card style.
class MetricCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final bool isGradient;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.isGradient = false,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGradient = isGradient
        ? (gradient ?? AppColors.heroGradient)
        : null;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGradient ? null : AppColors.cardSurface,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isGradient
                ? AppColors.primaryPurple.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: isGradient
            ? null
            : Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: isGradient ? Colors.white70 : AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isGradient ? Colors.white70 : AppColors.textSecondary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isGradient ? Colors.white70 : AppColors.textSecondary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
