import 'package:crm_pos/constants/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permission key strings are unchanged (stored in the database)', () {
    expect(Permissions.viewDashboard, 'view_dashboard');
    expect(Permissions.viewCrmOverview, 'view_crm_overview');
    expect(Permissions.manageCustomers, 'manage_customers');
    expect(Permissions.viewInventory, 'view_inventory');
    expect(Permissions.editInventory, 'edit_inventory');
    expect(Permissions.usePos, 'use_pos');
    expect(Permissions.manageExpenses, 'manage_expenses');
  });

  test('noneGranted matches the add-staff defaults, in order, and is mutable',
      () {
    final map = Permissions.noneGranted();
    expect(map.keys.toList(), [
      'view_dashboard',
      'view_crm_overview',
      'manage_customers',
      'view_inventory',
      'edit_inventory',
      'use_pos',
      'manage_expenses',
    ]);
    expect(map.values.every((v) => v == false), isTrue);
    map['use_pos'] = true; // must not throw
    expect(Permissions.noneGranted()['use_pos'], isFalse); // fresh each time
  });

  test('both label maps cover the same keys in the same order', () {
    expect(Permissions.detailedLabels.keys.toList(),
        Permissions.shortLabels.keys.toList());
    expect(Permissions.shortLabels['use_pos'], 'Use POS');
    expect(Permissions.detailedLabels['use_pos'],
        'Use POS (Make sales/checkout)');
  });
}
