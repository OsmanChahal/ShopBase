/// Represents a payment made by a customer against their balance.
class Payment {
  final String id;
  final String customerId;
  final double amountUsd;
  final String? note;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.customerId,
    required this.amountUsd,
    this.note,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      amountUsd: (json['amount_usd'] as num).toDouble(),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'amount_usd': amountUsd,
      'note': note,
    };
  }
}
