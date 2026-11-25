/// Longest location name the forms accept (UI-only rule).
const kLocationNameMaxLength = 40;

/// Validation message for a location name, or null if it's acceptable.
///
/// [name] is the trimmed text. [otherNames] are the names it must not
/// duplicate, compared ignoring case (on edit, exclude the location's own
/// name). An empty name returns [emptyMessage]: the add form passes null and
/// blocks saving separately; the edit form passes 'Name is required'.
String? validateLocationName(
  String name,
  Iterable<String> otherNames, {
  String? emptyMessage,
}) {
  if (name.isEmpty) return emptyMessage;
  if (name.length > kLocationNameMaxLength) {
    return 'Keep the name under 40 characters';
  }
  final lower = name.toLowerCase();
  if (otherNames.any((n) => n.toLowerCase() == lower)) {
    return 'A location with this name already exists';
  }
  return null;
}

/// Why a location can't be archived, or null if it can.
///
/// The server enforces the same rules except "primary", which is UI-only.
String? archiveBlockReason({
  required bool isPrimary,
  required int activeLocationCount,
  required int allocatedUnits,
}) {
  if (isPrimary) return "The primary location can't be archived.";
  if (activeLocationCount <= 1) {
    return "You can't archive your last active location.";
  }
  if (allocatedUnits > 0) {
    return 'Cannot archive while $allocatedUnits units are allocated. Transfer '
        'the remaining stock out first.';
  }
  return null;
}
