class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String link;
  final String category;
  final String source;
  final DateTime pubDate;
  final DateTime createdAt;
  bool isBookmarked;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.link,
    required this.category,
    required this.source,
    required this.pubDate,
    required this.createdAt,
    this.isBookmarked = false,
  });

  // Create from JSON response from backend
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      link: json['link'] as String? ?? '',
      category: json['category'] as String? ?? '',
      source: json['source'] as String? ?? '',
      pubDate: _parseDate(json['pubDate']),
      createdAt: _parseDate(json['createdAt']),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'link': link,
      'category': category,
      'source': source,
      'pubDate': pubDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isBookmarked': isBookmarked,
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

  // Copy with method for updating fields
  ArticleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnail,
    String? link,
    String? category,
    String? source,
    DateTime? pubDate,
    DateTime? createdAt,
    bool? isBookmarked,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      link: link ?? this.link,
      category: category ?? this.category,
      source: source ?? this.source,
      pubDate: pubDate ?? this.pubDate,
      createdAt: createdAt ?? this.createdAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(pubDate);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get estimated read time (assuming 200 words per minute)
  String get readTime {
    final wordCount = description.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }

  // Check if article has valid thumbnail
  bool get hasThumbnail {
    return thumbnail.isNotEmpty &&
           thumbnail != 'null' &&
           Uri.tryParse(thumbnail)?.hasAbsolutePath == true;
  }

  // Get placeholder color based on category
  int get placeholderColor {
    switch (category.toLowerCase()) {
      case 'technology':
        return 0xFF2196F3; // Blue
      case 'business':
        return 0xFF4CAF50; // Green
      case 'sports':
        return 0xFFFF9800; // Orange
      case 'entertainment':
        return 0xFF9C27B0; // Purple
      case 'health':
        return 0xFFF44336; // Red
      case 'science':
        return 0xFF00BCD4; // Cyan
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }
}
