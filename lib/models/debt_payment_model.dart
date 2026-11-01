class DebtPaymentModel {
  final int id;
  final int debtId;
  final int amountPaid;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;

  DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amountPaid,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'] as int,
      debtId: json['debt_id'] as int,
      amountPaid: (json['amount_paid'] as num).toInt(),
      paymentMethod: json['payment_method'] ?? 'Tunai',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
