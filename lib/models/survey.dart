
class Survey {
  final int id;
  final String title;
  final String description;
  final int? categoryId;
  final String categoryName;
  final String latitude;
  final String longitude;
  final String? photo;

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName = '',
    this.latitude = '',
    this.longitude = '',
    this.photo,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    final category = json['category'];

    return Survey(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      categoryId: int.tryParse(
        '${json['category_id'] ?? category?['id'] ?? ''}',
      ),
      categoryName: category is Map
          ? '${category['name'] ?? category['title'] ?? ''}'
          : '${json['category_name'] ?? ''}',
      latitude: '${json['latitude'] ?? ''}',
      longitude: '${json['longitude'] ?? ''}',
      photo: json['photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'latitude': latitude,
      'longitude': longitude,
      'photo': photo,
    };
  }
}
