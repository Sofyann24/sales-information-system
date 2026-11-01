import 'customer_model.dart';

class DebtModel {
  final int id;
  final DateTime? createdAt;
  final String? customerId;
  final CustomerModel? customer;
  final int? transactionId;
  final int totalDebt;
  final int remainingAmount;
  final String status;
  final DateTime? updatedAt;

  DebtModel({
    required this.id,
    this.createdAt,
    this.customerId,
    this.customer,
    this.transactionId,
    required this.totalDebt,
    required this.remainingAmount,
    required this.status,
    this.updatedAt,
  });

  String get customerName => customer?.nameCustomer ?? 'Tanpa Nama';
  String get nameCustomer => customer?.nameCustomer ?? 'Tanpa Nama';

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at']),
      customerId: json['customer_id'] as String?,
      // Parse object customers dari JOIN Supabase ke CustomerModel
      customer: json['customers'] != null
          ? CustomerModel.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      transactionId: json['transaction_id'] as int?,
      totalDebt: (json['total_debt'] as num).toInt(),
      remainingAmount: (json['remaining_amount'] as num).toInt(),
      status: json['status'] ?? 'Belum Lunas',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
