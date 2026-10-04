import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crm_pos/services/staff_service.dart';

void main() {
  late SupabaseClient adminClient;
  late SupabaseClient staffClient;
  late StaffService adminStaffService;
  late StaffService staffService;

  setUp(() {
    const supabaseUrl = 'https://efxgqkiyorfcmosvklob.supabase.co';
    const supabaseKey = 'sb_publishable_Tr9g1uq3jeP1DqHjwny3Mw_dN167AUO';
    
    adminClient = SupabaseClient(supabaseUrl, supabaseKey);
    staffClient = SupabaseClient(supabaseUrl, supabaseKey);
    adminStaffService = StaffService(adminClient);
    staffService = StaffService(staffClient);
  });

  tearDown(() async {
    await adminClient.dispose();
    await staffClient.dispose();
  });

  test('Deliverable 1: Live Broadcast for Staff Waiting Screen status transitions (Accept & Decline)', () async {
    final invitationId = 'test_invitation_${DateTime.now().millisecondsSinceEpoch}';
    print('\n--- TEST DELIVERABLE 1 START ---');
    print('[Test] Invitation ID: $invitationId');

    String? receivedStatus;
    
    // Staff subscribes to invitation status
    final staffChannel = staffService.subscribeToInvitationStatus(
      invitationId,
      (status) {
        print('[Test Staff Receiver] Received status update: $status');
        receivedStatus = status;
      },
    );

    // Wait for subscription to establish
    await Future.delayed(const Duration(seconds: 2));

    // Admin accepts request
    print('\n[Test Admin] Admin accepting request...');
    await adminStaffService.broadcastStatusUpdate(
      invitationId: invitationId,
      status: 'accepted',
    );

    await Future.delayed(const Duration(seconds: 2));
    expect(receivedStatus, equals('accepted'));
    print('[Test] SUCCESS: Staff screen received "accepted" live update!');

    // Reset and Admin declines request
    receivedStatus = null;
    print('\n[Test Admin] Admin declining request...');
    await adminStaffService.broadcastStatusUpdate(
      invitationId: invitationId,
      status: 'declined',
    );

    await Future.delayed(const Duration(seconds: 2));
    expect(receivedStatus, equals('declined'));
    print('[Test] SUCCESS: Staff screen received "declined" live update!');

    await staffService.unsubscribeFromInvitationStatus(staffChannel);
    print('--- TEST DELIVERABLE 1 END ---\n');
  });

  test('Deliverable 2: Live Broadcast for Admin Manage Staff screen on new staff request', () async {
    final businessId = 'test_business_${DateTime.now().millisecondsSinceEpoch}';
    print('\n--- TEST DELIVERABLE 2 START ---');
    print('[Test] Business ID: $businessId');

    bool adminNotificationFired = false;

    // Admin subscribes to staff requests for businessId
    final adminChannel = adminStaffService.subscribeToStaffRequests(
      businessId,
      () {
        print('[Test Admin Receiver] New staff request broadcast received! Refreshing list...');
        adminNotificationFired = true;
      },
    );

    // Wait for subscription to establish
    await Future.delayed(const Duration(seconds: 2));

    // Staff member submits name & broadcasts new request
    print('\n[Test Staff] Staff member submitted name, broadcasting new request...');
    await staffService.broadcastNewStaffRequest(businessId);

    await Future.delayed(const Duration(seconds: 2));
    expect(adminNotificationFired, isTrue);
    print('[Test] SUCCESS: Admin Manage Staff screen received "new_request" live update!');

    await adminStaffService.unsubscribeFromStaffRequests(adminChannel);
    print('--- TEST DELIVERABLE 2 END ---\n');
  });
}
