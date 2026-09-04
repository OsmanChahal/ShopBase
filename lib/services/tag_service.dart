import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tag.dart';

/// Service for managing the business tag library and customer–tag links.
class TagService {
  final SupabaseClient _client;

  TagService(this._client);

  // ── Tag library ────────────────────────────────────────────────────────────

  /// Fetches all tags for a business, ordered by creation date (newest first).
  Future<List<Tag>> getTagsForBusiness(String businessId) async {
    final data = await _client
        .from('tags')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => Tag.fromJson(row)).toList();
  }

  /// Creates a new tag in the business's library.
  ///
  /// Performs a case-insensitive duplicate check before inserting.
  /// Throws if a tag with the same label already exists.
  Future<Tag> addTag(String businessId, String label) async {
    // Check for case-insensitive duplicates
    final existing = await getTagsForBusiness(businessId);
    final normalised = label.trim().toLowerCase();
    if (existing.any((t) => t.label.toLowerCase() == normalised)) {
      throw Exception('A tag named "$label" already exists');
    }

    final data = await _client
        .from('tags')
        .insert({
          'business_id': businessId,
          'label': label.trim(),
          'source': 'manual',
        })
        .select()
        .single();

    return Tag.fromJson(data);
  }

  /// Deletes a tag from the library.
  ///
  /// The `on delete cascade` on `customer_tags.tag_id` automatically removes
  /// this tag from every customer who had it attached.
  Future<void> deleteTag(String tagId) async {
    await _client.from('tags').delete().eq('id', tagId);
  }

  // ── Customer–tag links ─────────────────────────────────────────────────────

  /// Fetches all tags currently attached to a specific customer.
  Future<List<Tag>> getTagsForCustomer(String customerId) async {
    final data = await _client
        .from('customer_tags')
        .select('tag_id, tags(*)')
        .eq('customer_id', customerId);

    return (data as List).map((row) {
      return Tag.fromJson(row['tags'] as Map<String, dynamic>);
    }).toList();
  }

  /// Attaches a tag to a customer.
  ///
  /// The unique constraint `(customer_id, tag_id)` prevents duplicates at the
  /// database level — this is a no-op if the link already exists.
  Future<void> attachTag(String customerId, String tagId) async {
    await _client.from('customer_tags').upsert(
      {
        'customer_id': customerId,
        'tag_id': tagId,
      },
      onConflict: 'customer_id,tag_id',
    );
  }

  /// Removes a tag from a customer (does not delete the tag from the library).
  Future<void> detachTag(String customerId, String tagId) async {
    await _client
        .from('customer_tags')
        .delete()
        .eq('customer_id', customerId)
        .eq('tag_id', tagId);
  }
}
