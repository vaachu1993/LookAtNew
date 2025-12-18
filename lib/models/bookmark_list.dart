class BookmarkList {
  final String id;
  final String sourceName;
  final String sourceLogoUrl;
  final String categoryTitle;
  final int storyCount;
  final bool isPrivate;
  final List<String> articleImageUrls;

  BookmarkList({
    required this.id,
    required this.sourceName,
    required this.sourceLogoUrl,
    required this.categoryTitle,
    required this.storyCount,
    required this.isPrivate,
    required this.articleImageUrls,
  });
}
