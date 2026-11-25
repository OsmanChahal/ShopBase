/// Rows Supabase (PostgREST) returns per request by default.
const supabasePageSize = 1000;

/// Fetches every row of a Supabase query, one page at a time.
///
/// Supabase returns at most [supabasePageSize] rows per request, so a plain
/// `select()` silently truncates larger tables. [buildFiltered] must build a
/// fresh filtered query each call (`from(...).select().eq(...)`); [orderBy]
/// columns are applied before `range()` and must together be unique (e.g.
/// `['id']`), or rows can repeat or go missing between pages.
Future<List<Map<String, dynamic>>> fetchAllPages(
  dynamic Function() buildFiltered,
  List<String> orderBy, {
  int pageSize = supabasePageSize,
}) async {
  final out = <Map<String, dynamic>>[];
  var from = 0;
  while (true) {
    dynamic q = buildFiltered();
    for (final col in orderBy) {
      q = q.order(col);
    }
    final List<dynamic> page = await q.range(from, from + pageSize - 1);
    out.addAll(page.cast<Map<String, dynamic>>());
    if (page.length < pageSize) break;
    from += pageSize;
  }
  return out;
}
