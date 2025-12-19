import 'article_model.dart';

class FavoriteModel {
  final String id;
  final String articleId;
  final String userId;
  final DateTime createdAt;
  final ArticleModel? article; // Optional, may be included in response

  FavoriteModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.createdAt,
    this.article,
  });

  // Create from JSON response from backend
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String? ?? '',
      articleId: json['articleId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      article: json['article'] != null
          ? ArticleModel.fromJson(json['article'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleId': articleId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      if (article != null) 'article': article!.toJson(),
    };
  }

  // Helper to parse dates safely
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

