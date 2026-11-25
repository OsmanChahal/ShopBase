import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_invitation.dart';
import '../models/business_member.dart';
import '../services/staff_service.dart';
import 'auth_provider.dart';

/// Provides the StaffService instance.
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(supabaseClientProvider));
});

/// Outcome of [StaffAccountActions.createAndActivate] when sign-up succeeded.
enum StaffActivationResult {
  /// Auth account created and business membership activated.
  activated,

  /// Auth account created, but `staff_activate_account` failed.
  setupFailed,
}

/// Staff-side account setup, run from the password setup screen once an
/// admin has accepted the invitation.
class StaffAccountActions {
  final Ref _ref;
  StaffAccountActions(this._ref);

  /// Signs up [email]/[password] with Supabase Auth, then activates the
  /// invitation (creates the business_members row) and refreshes auth state.
  ///
  /// Throws if sign-up itself fails. If sign-up succeeds but activation
  /// fails, returns [StaffActivationResult.setupFailed] instead of throwing.
  Future<StaffActivationResult> createAndActivate({
    required String invitationId,
    required String email,
    required String password,
  }) async {
    await _ref
        .read(supabaseClientProvider)
        .auth
        .signUp(email: email, password: password);

    try {
      await _ref.read(staffServiceProvider).activateStaffAccount(invitationId);
      // Refetch the new session so loading the business succeeds.
      _ref.invalidate(authProvider);
      return StaffActivationResult.activated;
    } catch (_) {
      return StaffActivationResult.setupFailed;
    }
  }
}

final staffAccountActionsProvider = Provider<StaffAccountActions>(
  (ref) => StaffAccountActions(ref),
);

/// Fetches the list of staff invitations for the current business.
final staffInvitationsProvider = FutureProvider<List<StaffInvitation>>((
  ref,
) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  return ref.watch(staffServiceProvider).getInvitations(business.id);
});

/// Fetches the list of staff members (active & inactive) for the current business.
final staffMembersProvider = FutureProvider<List<BusinessMember>>((
  ref,
) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  return ref.watch(staffServiceProvider).getStaffMembers(business.id);
});

