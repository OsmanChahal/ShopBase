class InvitationLookupResult {
  final String id;
  final String businessId;
  final String businessName;
  final String status;
  final String? email;

  InvitationLookupResult({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.status,
    this.email,
  });

  factory InvitationLookupResult.fromJson(Map<String, dynamic> json) {
    return InvitationLookupResult(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      businessName: json['business_name'] as String,
      status: json['status'] as String,
      email: json['email'] as String?,
    );
  }
}
