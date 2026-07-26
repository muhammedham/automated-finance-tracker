class CategoryModel {
  final int id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isDeleted = false,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }
}