/// Lightweight result for the pre-account lookup/status-check RPCs —
/// deliberately separate from StaffInvitation, since these carry
/// business_name alongside the invitation, which the full model doesn't.
class InvitationLookupResult {
  final String id;
  final String businessId;
  final String businessName;
  final String status;

  InvitationLookupResult({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.status,
  });

  factory InvitationLookupResult.fromJson(Map<String, dynamic> json) {
    return InvitationLookupResult(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String,
      status: json['status'] as String,
    );
  }
}
