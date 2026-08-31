/// Represents a business expense (recurring or one-off).
class Expense {
  final String? id;
  final String businessId;
  final String label;
  final double amountUsd;
  final bool isRecurring;
  final DateTime? createdAt;

  const Expense({
    this.id,
    required this.businessId,
    required this.label,
    required this.amountUsd,
    this.isRecurring = true,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      businessId: json['business_id'] as String,
      label: json['label'] as String,
      amountUsd: (json['amount_usd'] as num).toDouble(),
      isRecurring: json['is_recurring'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'label': label,
      'amount_usd': amountUsd,
      'is_recurring': isRecurring,
    };
  }

  Expense copyWith({
    String? id,
    String? businessId,
    String? label,
    double? amountUsd,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      label: label ?? this.label,
      amountUsd: amountUsd ?? this.amountUsd,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
