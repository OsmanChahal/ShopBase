// Form validators shared by more than one screen.
//
// Only validators that were identical across screens live here. Screens with
// stricter or different rules (e.g. register's email check, the staff invite
// regex) keep their own on purpose, so their behavior doesn't change.

/// Required email with a minimal `@` check. Used by login and staff register.
String? validateEmailBasic(String? value) {
  if (value == null || value.trim().isEmpty) return 'Please enter your email';
  if (!value.contains('@')) return 'Please enter a valid email';
  return null;
}

/// New password: required, at least 6 characters.
String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter a password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

/// Confirmation field: required and equal to [password].
String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return 'Please confirm your password';
  if (value != password) return 'Passwords do not match';
  return null;
}
