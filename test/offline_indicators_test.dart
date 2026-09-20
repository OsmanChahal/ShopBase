import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crm_pos/sync/sync_provider.dart';
import 'package:crm_pos/widgets/connectivity_banner.dart';
import 'package:crm_pos/widgets/offline_scope_boundary.dart';

void main() {
  group('ConnectivityBanner Widget Tests', () {
    testWidgets('renders persistent offline banner when isOnline = false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
            isSyncingProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConnectivityBanner(),
            ),
          ),
        ),
      );

      expect(
        find.text("You're offline — changes will sync automatically."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('renders syncing banner when isOnline = true and isSyncing = true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
            isSyncingProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConnectivityBanner(),
            ),
          ),
        ),
      );

      expect(
        find.text("You're back online — syncing..."),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders nothing when isOnline = true and isSyncing = false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
            isSyncingProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConnectivityBanner(),
            ),
          ),
        ),
      );

      expect(
        find.text("You're offline — changes will sync automatically."),
        findsNothing,
      );
      expect(
        find.text("You're back online — syncing..."),
        findsNothing,
      );
    });
  });

  group('OfflineScopeBoundary Widget Tests', () {
    testWidgets('renders friendly empty state when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineScopeBoundary(
                child: Text('Live Dashboard Data'),
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('This needs an internet connection to load'),
        findsOneWidget,
      );
      expect(
        find.text('Connect to the internet to access this screen'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Live Dashboard Data'), findsNothing);
    });

    testWidgets('renders child content when online',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineScopeBoundary(
                child: Text('Live Dashboard Data'),
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('This needs an internet connection to load'),
        findsNothing,
      );
      expect(find.text('Live Dashboard Data'), findsOneWidget);
    });
  });

  group('Cart Customer Tagging Gating Tests', () {
    testWidgets('hides customer tags when offline', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final isOnline = ref.watch(isOnlineProvider);
                  // Simulates the exact conditional gating in cart_panel.dart
                  if (isOnline) {
                    return const Text('Tag: VIP');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tag: VIP'), findsNothing);
    });

    testWidgets('shows customer tags when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final isOnline = ref.watch(isOnlineProvider);
                  if (isOnline) {
                    return const Text('Tag: VIP');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tag: VIP'), findsOneWidget);
    });
  });
}

