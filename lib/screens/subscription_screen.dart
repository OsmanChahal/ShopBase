import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Placeholder subscription screen shown after registration.
/// Whish Pay integration is not built yet — the pay button is disabled
/// and the user can skip to enter the app via "Continue" / "Skip for now."
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.baseWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 56,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Subscribe to ShopBase',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Unlock the full experience with a subscription.\n'
                'Online payment will be available soon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGray,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Whish Pay button — disabled, coming soon
              Opacity(
                opacity: 0.45,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: null, // Disabled — no integration yet
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Pay with Whish'),
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: AppColors.primaryPurple,
                      disabledForegroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coming soon',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inactiveGray,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 32),

              // Continue / Skip button — active, lets pilot testers through
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // Pop everything and let the auth listener in app.dart
                    // rebuild to the authenticated HomeScreen.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Skip for now'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can subscribe later from Settings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inactiveGray,
                  fontSize: 12,
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
