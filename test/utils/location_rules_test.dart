import 'package:crm_pos/utils/location_rules.dart';
import 'package:flutter_test/flutter_test.dart';

// Verbatim logic of the two screen versions before extraction.
String? legacyAddNameError(String trimmed, List<String> existing) {
  final n = trimmed;
  if (n.isEmpty) return null;
  if (n.length > 40) return 'Keep the name under 40 characters';
  if (existing.any((i) => i.toLowerCase() == n.toLowerCase())) {
    return 'A location with this name already exists';
  }
  return null;
}

String? legacyEditNameError(String typed, List<String> others) {
  final dup = others.any((x) => x.toLowerCase() == typed.toLowerCase());
  return typed.isEmpty
      ? 'Name is required'
      : typed.length > 40
          ? 'Keep the name under 40 characters'
          : dup
              ? 'A location with this name already exists'
              : null;
}

void main() {
  final names = ['', 'Main', 'main', 'Downtown', 'x' * 40, 'x' * 41, 'Ünïcode'];
  const existing = ['Main', 'Warehouse'];

  test('add-form variant matches legacy', () {
    for (final n in names) {
      expect(validateLocationName(n, existing), legacyAddNameError(n, existing),
          reason: '"$n"');
    }
  });

  test('edit-form variant matches legacy', () {
    for (final n in names) {
      expect(
        validateLocationName(n, existing, emptyMessage: 'Name is required'),
        legacyEditNameError(n, existing),
        reason: '"$n"',
      );
    }
  });

  group('archiveBlockReason', () {
    test('checks primary, then last location, then allocated units', () {
      expect(
        archiveBlockReason(isPrimary: true, activeLocationCount: 1, allocatedUnits: 9),
        "The primary location can't be archived.",
      );
      expect(
        archiveBlockReason(isPrimary: false, activeLocationCount: 1, allocatedUnits: 9),
        "You can't archive your last active location.",
      );
      expect(
        archiveBlockReason(isPrimary: false, activeLocationCount: 3, allocatedUnits: 12),
        'Cannot archive while 12 units are allocated. Transfer the remaining '
        'stock out first.',
      );
      expect(
        archiveBlockReason(isPrimary: false, activeLocationCount: 2, allocatedUnits: 0),
        isNull,
      );
    });
  });
}
