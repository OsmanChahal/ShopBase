class BusinessMember {
  final String id;
  final String businessId;
  final String userId;
  final String role; // 'admin' or 'staff'
  final Map<String, bool> permissions;
  final String status; // 'active', 'inactive'

  /// Optional display name from the linked staff_invitation row.
  final String? displayName;

  BusinessMember({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.status,
    this.displayName,
  });

  factory BusinessMember.fromJson(Map<String, dynamic> json) {
    Map<String, bool> parsedPermissions = {};
    if (json['permissions'] is Map) {
      (json['permissions'] as Map).forEach((key, value) {
        if (value is bool) {
          parsedPermissions[key.toString()] = value;
        } else if (value != null) {
          parsedPermissions[key.toString()] =
              value.toString().toLowerCase() == 'true';
        }
      });
    }

    return BusinessMember(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'staff',
      permissions: parsedPermissions,
      status: json['status'] as String? ?? 'active',
      displayName: json['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'role': role,
      'permissions': permissions,
      'status': status,
    };
  }

  bool hasPermission(String permissionKey) {
    if (role == 'admin') return true;
    return permissions[permissionKey] == true;
  }
}
