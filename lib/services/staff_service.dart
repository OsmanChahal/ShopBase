import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff_invitation.dart';
import '../models/invitation_lookup_result.dart';
import '../models/business_member.dart';

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

  /// Check if a pending or active invitation already exists for this email.
  /// Automatically cleans up old declined invitations for this email.
  Future<bool> checkDuplicateInvitation(String businessId, String email) async {
    try {
      await _client
          .from('staff_invitations')
          .delete()
          .eq('business_id', businessId)
          .ilike('email', email)
          .eq('status', 'declined');

      final response = await _client
          .from('staff_invitations')
          .select('id')
          .eq('business_id', businessId)
          .ilike('email', email)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check for existing invitations.');
    }
  }

  /// Fetch all staff members (role='staff') for a business.
  Future<List<BusinessMember>> getStaffMembers(String businessId) async {
    try {
      // Join with staff_invitations to surface the staff member's name.
      final response = await _client
          .from('business_members')
          .select(
            'id, business_id, user_id, role, permissions, status, '
            'staff_invitations!left(staff_full_name)',
          )
          .eq('business_id', businessId)
          .eq('role', 'staff');

      return (response as List).map((json) {
        final invRow = json['staff_invitations'];
        final String? name = invRow is Map
            ? invRow['staff_full_name'] as String?
            : null;

        // Flatten display_name into the JSON so fromJson picks it up.
        final flatJson = Map<String, dynamic>.from(json as Map)
          ..['display_name'] = name;

        return BusinessMember.fromJson(flatJson);
      }).toList();
    } catch (e) {
      // Fallback: load without join to avoid crashing on schema mismatches.
      try {
        final response = await _client
            .from('business_members')
            .select()
            .eq('business_id', businessId)
            .eq('role', 'staff');
        return (response as List)
            .map((json) => BusinessMember.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        throw Exception('Failed to load staff members.');
      }
    }
  }

  /// Update a staff member's permissions.
  Future<void> updateMemberPermissions(
    String memberId,
    Map<String, bool> permissions,
  ) async {
    try {
      await _client
          .from('business_members')
          .update({'permissions': permissions})
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to update staff permissions.');
    }
  }

  /// Update a staff member's status ('active' or 'inactive').
  Future<void> updateMemberStatus(String memberId, String status) async {
    try {
      await _client
          .from('business_members')
          .update({'status': status})
          .eq('id', memberId);
    } catch (e) {
      throw Exception('Failed to update staff status.');
    }
  }

  /// Cancel and delete an invitation.
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _client
          .from('staff_invitations')
          .delete()
          .eq('id', invitationId);
    } catch (e) {
      throw Exception('Failed to cancel invitation.');
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

  /// Look up a pending invitation by email. Returns null if none found.
  /// Callable with no authenticated session — used during staff registration.
  Future<InvitationLookupResult?> lookupInvitationByEmail(String email) async {
    try {
      final response = await _client.rpc(
        'staff_lookup_invitation',
        params: {'p_email': email},
      );

      final rows = response as List;
      if (rows.isEmpty) return null;
      return InvitationLookupResult.fromJson(
        rows.first as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to look up invitation. Please try again.');
    }
  }

  /// Submits the staff member's name against their invitation, flipping
  /// it to 'awaiting_approval'. Callable with no authenticated session.
  Future<void> submitStaffName({
    required String invitationId,
    required String fullName,
  }) async {
    try {
      await _client.rpc(
        'staff_submit_name',
        params: {'p_invitation_id': invitationId, 'p_full_name': fullName},
      );
    } catch (e) {
      throw Exception('Failed to submit your details. Please try again.');
    }
  }

  /// One-time status check — called when the waiting screen first loads,
  /// to catch up on anything that happened while the app was closed.
  Future<InvitationLookupResult> checkInvitationStatus(
    String invitationId,
  ) async {
    try {
      final response = await _client.rpc(
        'staff_check_status',
        params: {'p_invitation_id': invitationId},
      );

      final rows = response as List;
      final row = rows.first as Map<String, dynamic>;
      return InvitationLookupResult(
        id: invitationId,
        businessId: '', // not returned by this function — not needed here
        businessName: row['business_name'] as String,
        status: row['status'] as String,
      );
    } catch (e) {
      throw Exception('Failed to check invitation status.');
    }
  }

  /// Called right after a real Supabase Auth account is created, to
  /// activate the staff member's business_members row. Requires an
  /// authenticated session.
  Future<void> activateStaffAccount(String invitationId) async {
    try {
      await _client.rpc(
        'staff_activate_account',
        params: {'p_invitation_id': invitationId},
      );
    } catch (e) {
      throw Exception('Failed to activate your account. Please try again.');
    }
  }

  /// Subscribes to live status updates for one invitation via a Realtime
  /// Broadcast channel (not Postgres Changes — no RLS/auth needed to
  /// listen, since the unguessable invitationId is itself the access
  /// control). Returns the channel so the caller can unsubscribe later.
  RealtimeChannel subscribeToInvitationStatus(
    String invitationId,
    void Function(String status) onUpdate,
  ) {
    final channel = _client.channel('invitation_status_$invitationId');
    channel.onBroadcast(
      event: 'status_update',
      callback: (payload) {
        print('[Realtime] Received status_update payload on invitation_status_$invitationId: $payload');
        final Map<String, dynamic>? innerPayload =
            payload['payload'] is Map<String, dynamic>
                ? payload['payload'] as Map<String, dynamic>
                : null;
        final status = (innerPayload?['status'] ?? payload['status']) as String?;
        if (status != null) {
          print('[Realtime] Extracted status "$status", invoking onUpdate callback');
          onUpdate(status);
        } else {
          print('[Realtime] Could not extract status from payload: $payload');
        }
      },
    );
    channel.subscribe((status, [error]) {
      print('[Realtime] Subscription status for invitation_status_$invitationId: $status (error: $error)');
    });
    return channel;
  }

  /// Unsubscribes and cleans up a channel from [subscribeToInvitationStatus].
  Future<void> unsubscribeFromInvitationStatus(RealtimeChannel channel) async {
    try {
      await _client.removeChannel(channel);
    } catch (e) {
      print('[Realtime] Error unsubscribing from invitation status channel: $e');
    }
  }

  /// Admin accepts or declines a pending staff request: updates the
  /// invitation's [status] ('accepted' or 'declined'), then notifies the
  /// waiting staff device over realtime.
  ///
  /// Errors from the update are deliberately not wrapped, so callers can show
  /// the underlying message.
  Future<void> respondToInvitation({
    required String invitationId,
    required String status,
  }) async {
    await _client
        .from('staff_invitations')
        .update({'status': status})
        .eq('id', invitationId);
    await broadcastStatusUpdate(invitationId: invitationId, status: status);
  }

  /// Sends a status update broadcast — called by [respondToInvitation],
  /// right after the authenticated database update succeeds.
  Future<void> broadcastStatusUpdate({
    required String invitationId,
    required String status,
  }) async {
    try {
      final channel = _client.channel('invitation_status_$invitationId');
      channel.subscribe();
      print('[Realtime] Broadcasting status_update (status=$status) on invitation_status_$invitationId');
      await channel.sendBroadcastMessage(
        event: 'status_update',
        payload: {'status': status},
      );
    } catch (e) {
      print('[Realtime] Failed to broadcast status update: $e');
    }
  }

  /// Subscribes to live notifications of new/updated staff requests for
  /// a business — used by the admin's Manage Staff screen. Returns the
  /// channel so the caller can unsubscribe later.
  RealtimeChannel subscribeToStaffRequests(
    String businessId,
    void Function() onUpdate,
  ) {
    final channel = _client.channel('staff_requests_$businessId');
    channel.onBroadcast(
      event: 'new_request',
      callback: (payload) {
        print('[Realtime] Received new_request broadcast on staff_requests_$businessId: $payload');
        onUpdate();
      },
    );
    channel.subscribe((status, [error]) {
      print('[Realtime] Subscription status for staff_requests_$businessId: $status (error: $error)');
    });
    return channel;
  }

  /// Unsubscribes and cleans up a channel from [subscribeToStaffRequests].
  Future<void> unsubscribeFromStaffRequests(RealtimeChannel channel) async {
    try {
      await _client.removeChannel(channel);
    } catch (e) {
      print('[Realtime] Error unsubscribing from staff requests channel: $e');
    }
  }

  /// Notifies the business's admin(s) that a new staff request needs
  /// attention — called right after submitStaffName succeeds.
  Future<void> broadcastNewStaffRequest(String businessId) async {
    try {
      final channel = _client.channel('staff_requests_$businessId');
      channel.subscribe();
      print('[Realtime] Broadcasting new_request on staff_requests_$businessId');
      await channel.sendBroadcastMessage(
        event: 'new_request',
        payload: {},
      );
    } catch (e) {
      print('[Realtime] Failed to broadcast new staff request: $e');
    }
  }
}

