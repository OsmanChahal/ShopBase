import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import 'auth_provider.dart';

/// Provides the TagService instance.
final tagServiceProvider = Provider<TagService>((ref) {
  return TagService(ref.watch(supabaseClientProvider));
});

/// Fetches all tags for the current business (the tag library).
final tagListProvider = FutureProvider<List<Tag>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ref.watch(tagServiceProvider).getTagsForBusiness(business.id);
});

/// Fetches tags attached to a specific customer.
final customerTagsProvider =
    FutureProvider.family<List<Tag>, String>((ref, customerId) async {
  return ref.watch(tagServiceProvider).getTagsForCustomer(customerId);
});

/// Actions class for tag mutations — mirrors CustomerActions pattern.
class TagActions {
  final Ref ref;

  TagActions(this.ref);

  TagService get _service => ref.read(tagServiceProvider);

  /// Adds a new tag to the business library.
  Future<Tag> addTag(String label) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) throw Exception('No active business');
    final tag = await _service.addTag(business.id, label);
    ref.invalidate(tagListProvider);
    return tag;
  }

  /// Deletes a tag from the library (cascade-removes from all customers).
  Future<void> deleteTag(String tagId) async {
    await _service.deleteTag(tagId);
    ref.invalidate(tagListProvider);
    // Also invalidate any cached customer-tag lists since the tag may have
    // been attached to customers.
  }

  /// Attaches an existing tag to a customer.
  Future<void> attachTagToCustomer(String customerId, String tagId) async {
    await _service.attachTag(customerId, tagId);
    ref.invalidate(customerTagsProvider(customerId));
  }

  /// Removes a tag from a customer (does not delete the tag itself).
  Future<void> detachTagFromCustomer(String customerId, String tagId) async {
    await _service.detachTag(customerId, tagId);
    ref.invalidate(customerTagsProvider(customerId));
  }

  /// Creates a new tag AND immediately attaches it to a customer (checkout quick-add).
  Future<Tag> addAndAttachTag(String label, String customerId) async {
    final tag = await addTag(label);
    await _service.attachTag(customerId, tag.id);
    ref.invalidate(customerTagsProvider(customerId));
    return tag;
  }
}

/// Provider for tag actions.
final tagActionsProvider = Provider<TagActions>((ref) {
  return TagActions(ref);
});
