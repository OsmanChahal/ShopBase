/// Category to save from the product form.
///
/// - No [existingCategories] (none yet, or not loaded): the trimmed [typed]
///   text, or null if empty.
/// - An existing category chosen in the dropdown ([selected] is set and isn't
///   [createNewSentinel]): that category.
/// - "Create new" chosen: the trimmed [typed] text, but if it matches an
///   existing category ignoring case, the existing casing is reused so no
///   near-duplicate is created. Null if empty.
/// - Nothing chosen: null (category is optional).
String? resolveCategoryToSave({
  required List<String> existingCategories,
  required String? selected,
  required String typed,
  required String createNewSentinel,
}) {
  if (existingCategories.isEmpty) {
    final text = typed.trim();
    return text.isEmpty ? null : text;
  }

  if (selected != null && selected != createNewSentinel) {
    return selected;
  }

  if (selected == createNewSentinel) {
    final text = typed.trim();
    if (text.isEmpty) return null;

    for (final existing in existingCategories) {
      if (existing.toLowerCase() == text.toLowerCase()) {
        return existing; // reuse existing casing
      }
    }
    return text; // genuinely new
  }

  return null;
}
