class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name_category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name_category': name};
  }
}
