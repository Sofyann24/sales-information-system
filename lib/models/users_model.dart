class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.role,
    this.createdAt,
  });

  // Convert dari JSON Supabase ke Object Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? json['nama'],
      phone: json['phone'] ?? json['phone'],
      role: json['role'] ?? 'admin', // Default role
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // Convert dari Object Model ke JSON (jika butuh insert/update)
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'role': role};
  }

  // Getter pembantu untuk mengecek hak akses/role
  bool get isAdmin => role.toLowerCase() == 'owner';
  bool get isKasir => role.toLowerCase() == 'kasir';
}
