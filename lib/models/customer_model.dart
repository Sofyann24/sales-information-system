class CustomerModel {
  final String id;
  final String nameCustomer;
  final String phoneNumber;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalDebt;

  CustomerModel({
    required this.id,
    required this.nameCustomer,
    required this.phoneNumber,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.totalDebt = 0,
  });
  
  String get nameCustomers => nameCustomer;
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      nameCustomer: json['name_customer'] ?? 'Tanpa Nama',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      totalDebt: (json['total_debt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_customer': nameCustomer,
      'phone_number': phoneNumber,
      'address': address,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_debt': totalDebt,
    };
  }
}
