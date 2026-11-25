import 'package:crm_pos/models/expense.dart';
import 'package:crm_pos/models/product.dart';
import 'package:crm_pos/providers/customer_detail_provider.dart';
import 'package:crm_pos/providers/expense_provider.dart';
import 'package:crm_pos/providers/pos_provider.dart';
import 'package:crm_pos/services/crm_analytics_service.dart' show DateValue;
import 'package:crm_pos/utils/chart_buckets.dart';
import 'package:crm_pos/utils/product_rules.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

// Characterization tests for logic moved out of screens in refactor phase 3c.
// Legacy functions are verbatim copies of the screen code before extraction.

DateTimeRange? legacyHistoryRange(
    HistoryPeriod period, DateTimeRange? customRange, DateTime now) {
  switch (period) {
    case HistoryPeriod.allTime:
      return null;
    case HistoryPeriod.thisWeek:
      final weekday = now.weekday;
      final monday = now.subtract(Duration(days: weekday - 1));
      return DateTimeRange(
        start: DateTime(monday.year, monday.month, monday.day),
        end: now,
      );
    case HistoryPeriod.thisMonth:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    case HistoryPeriod.lastMonth:
      final firstOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final lastOfLastMonth = DateTime(now.year, now.month, 0);
      return DateTimeRange(start: firstOfLastMonth, end: lastOfLastMonth);
    case HistoryPeriod.custom:
      return customRange;
  }
}

String? legacyResolveCategory(List<String> categories, String? selected,
    String controllerText, String sentinel) {
  if (categories.isEmpty) {
    final typed = controllerText.trim();
    return typed.isEmpty ? null : typed;
  }
  if (selected != null && selected != sentinel) return selected;
  if (selected == sentinel) {
    final typed = controllerText.trim();
    if (typed.isEmpty) return null;
    for (final existing in categories) {
      if (existing.toLowerCase() == typed.toLowerCase()) return existing;
    }
    return typed;
  }
  return null;
}

Product product(String name, {String? category, int quantity = 10}) => Product(
      businessId: 'b',
      name: name,
      category: category,
      costPriceUsd: 1,
      sellPriceUsd: 2,
      quantity: quantity,
    );

void main() {
  group('historyPeriodRange', () {
    final nows = [
      DateTime(2026, 3, 4, 15, 30), // Wednesday
      DateTime(2026, 3, 2, 0, 0), // Monday midnight
      DateTime(2026, 3, 8, 23, 59), // Sunday
      DateTime(2026, 1, 15, 9), // January: last month is previous year
      DateTime(2024, 3, 1, 12), // leap year boundary
    ];
    final custom = DateTimeRange(
        start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 10));

    test('matches the legacy screen getter for every period', () {
      for (final now in nows) {
        for (final period in HistoryPeriod.values) {
          for (final c in [null, custom]) {
            expect(
              historyPeriodRange(period, customRange: c, now: now),
              legacyHistoryRange(period, c, now),
              reason: '$period at $now (custom: $c)',
            );
          }
        }
      }
    });

    test('filter key encodes the range as ISO strings', () {
      expect(customerSalesFilterKey('c1', null), (id: 'c1', from: null, to: null));
      expect(
        customerSalesFilterKey('c1', custom),
        (
          id: 'c1',
          from: DateTime(2026, 2, 1).toIso8601String(),
          to: DateTime(2026, 2, 10).toIso8601String(),
        ),
      );
    });
  });

  group('chart buckets', () {
    test('aggregateWeekly sums by Monday and sorts', () {
      final daily = [
        DateValue(date: DateTime(2026, 3, 10), value: 2), // Tue wk2
        DateValue(date: DateTime(2026, 3, 2), value: 1), // Mon wk1
        DateValue(date: DateTime(2026, 3, 8), value: 4), // Sun wk1
        DateValue(date: DateTime(2026, 3, 9), value: 3), // Mon wk2
      ];
      final weekly = aggregateWeekly(daily);
      expect(weekly.map((d) => d.date),
          [DateTime(2026, 3, 2), DateTime(2026, 3, 9)]);
      expect(weekly.map((d) => d.value), [5, 5]);
      expect(aggregateWeekly(const []), isEmpty);
    });

    test('shouldUseWeekly is true only beyond 31 days', () {
      final start = DateTime(2026, 1, 1);
      expect(shouldUseWeekly(DateTimeRange(start: start, end: start.add(const Duration(days: 31)))), isFalse);
      expect(shouldUseWeekly(DateTimeRange(start: start, end: start.add(const Duration(days: 32)))), isTrue);
    });

    test('chartGridInterval steps', () {
      expect([0, -3, 5, 6, 20, 21, 100, 101, 500, 501, 2000, 2001, 10000]
              .map((v) => chartGridInterval(v.toDouble())),
          [1, 1, 1, 5, 5, 20, 20, 100, 100, 500, 500, 401, 2000]);
    });
  });

  group('resolveCategoryToSave', () {
    const sentinel = '__create_new_category__';
    final cases = [
      (<String>[], null, '  Drinks  '),
      (<String>[], null, '   '),
      (<String>[], 'Food', 'ignored'),
      (['Drinks', 'Food'], 'Food', 'x'),
      (['Drinks', 'Food'], sentinel, ' drinks '),
      (['Drinks', 'Food'], sentinel, 'Snacks'),
      (['Drinks', 'Food'], sentinel, '  '),
      (['Drinks', 'Food'], null, 'Snacks'),
    ];

    test('matches the legacy screen method', () {
      for (final (cats, selected, typed) in cases) {
        expect(
          resolveCategoryToSave(
            existingCategories: cats,
            selected: selected,
            typed: typed,
            createNewSentinel: sentinel,
          ),
          legacyResolveCategory(cats, selected, typed, sentinel),
          reason: '$cats / $selected / "$typed"',
        );
      }
    });

    test('reuses existing casing', () {
      expect(
        resolveCategoryToSave(
          existingCategories: ['Drinks'],
          selected: sentinel,
          typed: 'DRINKS',
          createNewSentinel: sentinel,
        ),
        'Drinks',
      );
    });
  });

  test('ExpenseGroups splits and totals like the old inline code', () {
    const expenses = [
      Expense(businessId: 'b', label: 'Rent', amountUsd: 500),
      Expense(businessId: 'b', label: 'Repair', amountUsd: 40.5, isRecurring: false),
      Expense(businessId: 'b', label: 'Power', amountUsd: 80.25),
    ];
    final g = ExpenseGroups(expenses);
    expect(g.recurring.map((e) => e.label), ['Rent', 'Power']);
    expect(g.oneOff.map((e) => e.label), ['Repair']);
    expect(g.recurringTotal, 580.25);
    expect(g.oneOffTotal, 40.5);
    expect(ExpenseGroups(const []).recurringTotal, 0.0);
  });

  group('POS category helpers', () {
    final products = [
      product('Cola', category: ' Drinks '),
      product('Water', category: 'Drinks'),
      product('Chips', category: 'Snacks'),
      product('Misc'),
      product('Blank', category: '  '),
    ];

    test('productCountsByCategory trims and skips empty', () {
      expect(productCountsByCategory(products), {'Drinks': 2, 'Snacks': 1});
    });

    test('filterByCategory', () {
      expect(identical(filterByCategory(products, null), products), isTrue);
      expect(filterByCategory(products, 'Drinks').map((p) => p.name),
          ['Cola', 'Water']);
    });
  });

  test('Product.isOutOfStock', () {
    expect(product('a', quantity: 0).isOutOfStock, isTrue);
    expect(product('a', quantity: -2).isOutOfStock, isTrue);
    expect(product('a', quantity: 1).isOutOfStock, isFalse);
  });
}
