/// Staff permission keys, stored in `business_members.permissions` and checked
/// with `hasPermissionProvider` / `BusinessMember.hasPermission`.
///
/// The string values are a contract with existing database rows: never change
/// them. Admins pass every check regardless of these flags.
abstract final class Permissions {
  static const viewDashboard = 'view_dashboard';
  static const viewCrmOverview = 'view_crm_overview';
  static const manageCustomers = 'manage_customers';
  static const viewInventory = 'view_inventory';
  static const editInventory = 'edit_inventory';
  static const usePos = 'use_pos';
  static const manageExpenses = 'manage_expenses';

  /// Short labels, used by the edit-staff sheet. Key order is display order.
  static const shortLabels = <String, String>{
    viewDashboard: 'View Dashboard',
    viewCrmOverview: 'View CRM Overview',
    manageCustomers: 'Manage Customers',
    viewInventory: 'View Inventory',
    editInventory: 'Edit Inventory',
    usePos: 'Use POS',
    manageExpenses: 'Manage Expenses',
  };

  /// Descriptive labels, used by the add-staff flow. Key order is display order.
  static const detailedLabels = <String, String>{
    viewDashboard: 'View Dashboard',
    viewCrmOverview: 'View CRM Overview',
    manageCustomers: 'Manage Customers (View/Edit profiles, tags, WhatsApp)',
    viewInventory: 'View Inventory',
    editInventory: 'Edit Inventory (Add/Edit/Delete products, adjust stock)',
    usePos: 'Use POS (Make sales/checkout)',
    manageExpenses: 'Manage Expenses',
  };

  /// A new, mutable map with every permission switched off, in display order.
  static Map<String, bool> noneGranted() => {
        for (final key in shortLabels.keys) key: false,
      };
}
