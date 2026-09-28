import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_invitation.dart';
import '../services/staff_service.dart';
import 'auth_provider.dart';

/// Provides the StaffService instance.
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(supabaseClientProvider));
});

/// Fetches the list of staff invitations for the current business.
final staffInvitationsProvider = FutureProvider<List<StaffInvitation>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  
  return ref.watch(staffServiceProvider).getInvitations(business.id);
});
