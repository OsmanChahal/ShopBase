/// User-facing text for a caught error: its `toString()` with every
/// `"Exception: "` prefix removed.
String errorText(Object error) =>
    error.toString().replaceAll('Exception: ', '');
