class StaffInvitation {
  final String id;
  final String businessId;
  final String email;
  final Map<String, bool> permissions;
  final String status;
  final String? staffFullName;
  final DateTime invitedAt;
  final DateTime? respondedAt;

  const StaffInvitation({
    required this.id,
    required this.businessId,
    required this.email,
    required this.permissions,
    required this.status,
    this.staffFullName,
    required this.invitedAt,
    this.respondedAt,
  });

  factory StaffInvitation.fromJson(Map<String, dynamic> json) {
    return StaffInvitation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      email: json['email'] as String,
      permissions: Map<String, bool>.from(json['permissions'] as Map),
      status: json['status'] as String,
      staffFullName: json['staff_full_name'] as String?,
      invitedAt: DateTime.parse(json['invited_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'email': email,
      'permissions': permissions,
      'status': status,
      'staff_full_name': staffFullName,
      'invited_at': invitedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }
}
