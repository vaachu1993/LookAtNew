import 'article_model.dart';

class FavoriteModel {
  final String id;
  final String articleId;
  final String userId;
  final DateTime createdAt;
  final ArticleModel? article;

  FavoriteModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.createdAt,
    this.article,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    // Try multiple possible keys for the article object
    Map<String, dynamic>? articleJson;

    // Check for 'article' key (lowercase)
    if (json['article'] != null && json['article'] is Map<String, dynamic>) {
      articleJson = json['article'] as Map<String, dynamic>;
    } else if (json['title'] != null) {
      // Backend trả về flat structure - construct articleJson từ root fields
      articleJson = {
        'id': json['articleId'],
        'title': json['title'],
        'description': json['description'],
        'thumbnail': json['imageUrl'],
        'link': json['link'],
        'category': json['category'] ?? '', // Backend cần thêm field này
        'source': json['source'],
        'pubDate': json['pubDate'],
        'createdAt': json['savedAt'] ?? json['createdAt'],
      };
    }

    return FavoriteModel(
      id: json['id'] as String? ?? '',
      articleId: json['articleId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      article: articleJson != null
          ? ArticleModel.fromJson(articleJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleId': articleId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (article != null) 'article': article!.toJson(),
    };
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

