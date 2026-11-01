class ProductModel {
  final String id;
  final String nameProduct;
  final int price;
  final String? unit;
  final String? categoryId;
  final int stock;
  final int stockMin;
  final String? imageUrl;
  final num? priceModal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.nameProduct,
    required this.price,
    this.unit,
    this.categoryId,
    required this.stock,
    this.stockMin = 5,
    this.imageUrl,
    this.priceModal,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',

      nameProduct: json['name_product']?.toString() ?? '',

      price: (json['price'] != null) ? (json['price'] as num).toInt() : 0,

      unit: json['unit']?.toString() ?? '',

      // ✅ DIPERBAIKI: String UUID dari Supabase di-parse ke String aman
      categoryId: json['category_id']?.toString(),

      stock: (json['stock'] != null) ? (json['stock'] as num).toInt() : 0,

      stockMin: (json['stock_min'] != null)
          ? (json['stock_min'] as num).toInt()
          : 5,

      imageUrl: json['image_url']?.toString() ?? '',

      priceModal: (json['price_modal'] != null)
          ? (json['price_modal'] as num).toInt()
          : null,

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_product': nameProduct,
      'price': price,
      'unit': unit,
      'category_id': categoryId,
      'stock': stock,
      'stock_min': stockMin,
      'image_url': imageUrl,
      'price_modal': priceModal,
    };
  }

  // Getter pembantu untuk status stok
  bool get isLowStock => stock <= stockMin;
}
