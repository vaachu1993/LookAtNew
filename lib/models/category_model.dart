/// Category model matching backend CategoryResponse
class CategoryModel {
  final String id;
  final String name;
  final List<RssSource> rssSources;

  CategoryModel({
    required this.id,
    required this.name,
    required this.rssSources,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rssSources: (json['rssSources'] as List<dynamic>?)
          ?.map((item) => RssSource.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rssSources': rssSources.map((source) => source.toJson()).toList(),
    };
  }
}

/// RSS Source model
class RssSource {
  final String name;
  final String url;

  RssSource({
    required this.name,
    required this.url,
  });

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}

