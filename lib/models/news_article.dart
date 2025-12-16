class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String publisher;
  final String publisherLogo;
  final DateTime publishedAt;
  final String category;
  final int readTimeMinutes;
  final String url;
  final bool isFeatured;
  final bool isBookmarked;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publisher,
    required this.publisherLogo,
    required this.publishedAt,
    required this.category,
    required this.readTimeMinutes,
    required this.url,
    this.isFeatured = false,
    this.isBookmarked = false,
  });

  NewsArticle copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? publisher,
    String? publisherLogo,
    DateTime? publishedAt,
    String? category,
    int? readTimeMinutes,
    String? url,
    bool? isFeatured,
    bool? isBookmarked,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      publisher: publisher ?? this.publisher,
      publisherLogo: publisherLogo ?? this.publisherLogo,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      url: url ?? this.url,
      isFeatured: isFeatured ?? this.isFeatured,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'publisher': publisher,
      'publisherLogo': publisherLogo,
      'publishedAt': publishedAt.toIso8601String(),
      'category': category,
      'readTimeMinutes': readTimeMinutes,
      'url': url,
      'isFeatured': isFeatured,
      'isBookmarked': isBookmarked,
    };
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      publisher: json['publisher'] as String,
      publisherLogo: json['publisherLogo'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      category: json['category'] as String,
      readTimeMinutes: json['readTimeMinutes'] as int,
      url: json['url'] as String,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  String get readTime => '$readTimeMinutes min read';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

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
}

