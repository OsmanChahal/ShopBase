import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_invitation.dart';

class StaffService {
  final SupabaseClient _client;

  StaffService(this._client);

  /// Fetch all staff invitations for a business, most recent first.
  Future<List<StaffInvitation>> getInvitations(String businessId) async {
    try {
      final response = await _client
          .from('staff_invitations')
          .select()
          .eq('business_id', businessId)
          .order('invited_at', ascending: false);

      return (response as List)
          .map((json) => StaffInvitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load staff invitations. Please try again.');
    }
  }

  /// Check if a pending or accepted invitation already exists for this email.
  Future<bool> checkDuplicateInvitation(String businessId, String email) async {
    try {
      final response = await _client
          .from('staff_invitations')
          .select('id')
          .eq('business_id', businessId)
          .ilike('email', email)
          .neq('status', 'declined')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check for existing invitations.');
    }
  }

  /// Create a new staff invitation.
  Future<StaffInvitation> createInvitation({
    required String businessId,
    required String email,
    required Map<String, bool> permissions,
  }) async {
    try {
      final response = await _client
          .from('staff_invitations')
          .insert({
            'business_id': businessId,
            'email': email.toLowerCase(),
            'permissions': permissions,
            'status': 'invited',
          })
          .select()
          .single();

      return StaffInvitation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create invitation. Please try again.');
    }
  }
}
