import 'package:aplikasi_warung_supabase/models/transaction_detail_model.dart';

class TransactionModel {
  final int id;
  final String invoiceNumber;
  final String? customerId;
  final num totalPrice;
  final String paymentMethod;
  final DateTime createdAt;
  final List<TransactionDetailModel> transactionDetails;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.totalPrice,
    required this.paymentMethod,
    required this.createdAt,
    required this.transactionDetails,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    // Safely parse nested list transaction_details
    final rawDetails = map['transaction_details'] as List<dynamic>? ?? [];
    final detailsList = rawDetails
        .map(
          (item) =>
              TransactionDetailModel.fromMap(item as Map<String, dynamic>),
        )
        .toList();

    return TransactionModel(
      id: parseInt(map['id']),
      invoiceNumber:
          map['invoice_number']?.toString() ??
          map['invoice_no']?.toString() ??
          '',
      customerId: map['customer_id']?.toString(),
      totalPrice: parseNum(map['total_price'] ?? map['total']),
      paymentMethod:
          map['payment_method']?.toString() ??
          map['status']?.toString() ??
          'Cash',
      createdAt: parseDate(map['created_at'] ?? map['date']),
      transactionDetails: detailsList,
    );
  }
}
