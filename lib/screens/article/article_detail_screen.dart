import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/article_model.dart';
import '../../models/favorite_model.dart';
import '../../services/favorite_service.dart';
import '../../services/article_content_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final ArticleContentService _contentService = ArticleContentService();
  late ArticleModel _article;
  bool _isTogglingFavorite = false;
  bool _isLoadingContent = true;
  String? _articleHtmlContent;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _fetchArticleContent();
  }

  Future<void> _fetchArticleContent() async {
    print('🚀 Starting fetch for article: ${_article.title}');
    print('🔗 Link: ${_article.link}');

    setState(() {
      _isLoadingContent = true;
      _contentError = null;
    });

    final response = await _contentService.fetchArticleContent(_article.link);

    print('📥 Response received - Success: ${response.isSuccess}');
    if (response.isSuccess) {
      print('✅ Content length: ${response.content?.length ?? 0}');
    } else {
      print('❌ Error: ${response.error}');
    }

    setState(() {
      _isLoadingContent = false;
      if (response.isSuccess) {
        _articleHtmlContent = response.content;
      } else {
        _contentError = response.error;
      }
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    final wasBookmarked = _article.isBookmarked;

    // Optimistic update
    setState(() {
      _article = _article.copyWith(isBookmarked: !wasBookmarked);
    });

    if (wasBookmarked) {
      // Remove bookmark - need to find favoriteId first
      final favoritesResponse = await _favoriteService.getFavorites();
      if (favoritesResponse.isSuccess && favoritesResponse.favorites != null) {
        final favorite = favoritesResponse.favorites!
            .firstWhere((f) => f.articleId == _article.id, orElse: () => FavoriteModel(
          id: '',
          articleId: '',
          userId: '',
          createdAt: DateTime.now(),
        ));

        if (favorite.id.isNotEmpty) {
          final response = await _favoriteService.removeFavorite(favorite.id);
          if (!response.isSuccess) {
            // Revert on error
            setState(() {
              _article = _article.copyWith(isBookmarked: true);
            });
            if (mounted) {
              toastification.show(
                context: context,
                type: ToastificationType.error,
                style: ToastificationStyle.fillColored,
                title: const Text('Lỗi'),
                description: Text(response.error ?? 'Không thể xóa bookmark'),
                alignment: Alignment.bottomCenter,
                autoCloseDuration: const Duration(seconds: 2),
                icon: const Icon(Icons.error_outline),
                showProgressBar: false,
                closeButtonShowType: CloseButtonShowType.none,
                animationDuration: const Duration(milliseconds: 300),
              );
            }
          }
        } else {
          // Favorite not found, just update UI
          if (mounted) {
            toastification.show(
              context: context,
              type: ToastificationType.warning,
              style: ToastificationStyle.fillColored,
              title: const Text('Cảnh báo'),
              description: const Text('Không tìm thấy bookmark'),
              alignment: Alignment.bottomCenter,
              autoCloseDuration: const Duration(seconds: 2),
              icon: const Icon(Icons.warning_outlined),
              showProgressBar: false,
              closeButtonShowType: CloseButtonShowType.none,
              animationDuration: const Duration(milliseconds: 300),
            );
          }
        }
      } else {
        // Revert on error
        setState(() {
          _article = _article.copyWith(isBookmarked: true);
        });
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Lỗi'),
            description: Text(favoritesResponse.error ?? 'Không thể tải danh sách bookmark'),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            icon: const Icon(Icons.error_outline),
            showProgressBar: false,
            closeButtonShowType: CloseButtonShowType.none,
            animationDuration: const Duration(milliseconds: 300),
          );
        }
      }
    } else {
      // Add bookmark
      final response = await _favoriteService.addFavorite(_article.id);
      if (!response.isSuccess) {
        // Revert on error
        setState(() {
          _article = _article.copyWith(isBookmarked: false);
        });
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            title: const Text('Lỗi'),
            description: Text(response.error ?? 'Không thể lưu bookmark'),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            icon: const Icon(Icons.error_outline),
            showProgressBar: false,
            closeButtonShowType: CloseButtonShowType.none,
            animationDuration: const Duration(milliseconds: 300),
          );
        }
      } else {
        // Show success notification
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: const Text('Đã lưu'),
            description: const Text('Bài báo đã được thêm vào Bookmark'),
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            icon: const Icon(Icons.bookmark),
            showProgressBar: false,
            closeButtonShowType: CloseButtonShowType.none,
            animationDuration: const Duration(milliseconds: 300),
          );
        }
      }
    }

    setState(() {
      _isTogglingFavorite = false;
    });
  }

  void _shareArticle() {
    Share.share(
      '${_article.title}\n\n${_article.link}',
      subject: _article.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _article.isBookmarked ? const Color(0xFFE20035) : Colors.black,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: _shareArticle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            _buildHeroImage(),

            // Content - BỎ PADDING Ở ĐÂY
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, Source - VẪN CÓ PADDING
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 20),
                      _buildSourceSection(),
                      const SizedBox(height: 24),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Body Content - KHÔNG PADDING để ảnh full width
                _buildBodyContent(),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (!_article.hasThumbnail) {
      return Container(
        width: double.infinity,
        height: 250,
        color: Color(_article.placeholderColor).withValues(alpha: 0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(_article.category),
              color: Color(_article.placeholderColor).withValues(alpha: 0.7),
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              _article.category.toUpperCase(),
              style: TextStyle(
                color: Color(_article.placeholderColor),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      _article.thumbnail,
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 250,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFFE20035),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 250,
          color: Color(_article.placeholderColor).withValues(alpha: 0.2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(_article.category),
                color: Color(_article.placeholderColor).withValues(alpha: 0.7),
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                _article.category.toUpperCase(),
                style: TextStyle(
                  color: Color(_article.placeholderColor),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      _article.title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.3,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSourceSection() {
    return Row(
      children: [
        // Source logo/avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _article.source.isNotEmpty
                  ? _article.source[0].toUpperCase()
                  : 'N',
              style: const TextStyle(
                color: Color(0xFFE20035),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Source info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Source name
                  Text(
                    _article.source,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Following badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Following',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Meta info
              Row(
                children: [
                  Text(
                    _article.timeAgo,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    _article.readTime,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    // Show loading state
    if (_isLoadingContent) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFE20035),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đang tải nội dung bài báo...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error state with fallback to description
    if (_contentError != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Không thể tải nội dung đầy đủ',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contentError!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _fetchArticleContent,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Show description as fallback
            Text(
              'Hiển thị mô tả từ RSS:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Fallback to description
            _buildDescriptionContent(),
          ],
        ),
      );
    }

    // Show HTML content
    if (_articleHtmlContent != null) {
      try {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Html(
              data: _articleHtmlContent!,
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (extensionContext) {
                    final element = extensionContext.element;
                    final src = element?.attributes['src'];

                    if (src == null || src.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Check if img is inside figure (will be handled by figure extension)
                    final parent = element?.parent;
                    if (parent?.localName == 'figure') {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      child: Image.network(
                        src,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFE20035),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                TagExtension(
                  tagsToExtend: {"figure"},
                  builder: (extensionContext) {
                    final element = extensionContext.element;

                    // Find img tag
                    final imgElement = element?.querySelector('img');
                    final imgSrc = imgElement?.attributes['src'];

                    // Find caption
                    final captionElement = element?.querySelector('figcaption');
                    final captionText = captionElement?.text ?? '';

                    if (imgSrc == null || imgSrc.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.network(
                            imgSrc,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFFE20035),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (captionText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Text(
                                captionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.all(20),
                  fontSize: FontSize(16),
                  lineHeight: const LineHeight(1.7),
                  color: Colors.black87,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 16),
                  textAlign: TextAlign.justify,
                ),
                "h1": Style(
                  fontSize: FontSize(24),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24, bottom: 16),
                  color: Colors.black,
                ),
                "h2": Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 20, bottom: 14),
                  color: Colors.black,
                ),
                "h3": Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 18, bottom: 12),
                  color: Colors.black,
                ),
                "h4": Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 16, bottom: 10),
                  color: Colors.black,
                ),
                "table": Style(
                  width: Width(double.infinity),
                  margin: Margins.symmetric(vertical: 16),
                ),
                "blockquote": Style(
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFE20035),
                      width: 4,
                    ),
                  ),
                  margin: Margins.symmetric(vertical: 16),
                  padding: HtmlPaddings.only(left: 16, right: 0, top: 8, bottom: 8),
                  backgroundColor: Colors.grey.withValues(alpha: 0.05),
                ),
                "ul": Style(
                  margin: Margins.only(bottom: 16),
                  padding: HtmlPaddings.only(left: 20),
                ),
                "ol": Style(
                  margin: Margins.only(bottom: 16),
                  padding: HtmlPaddings.only(left: 20),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 8),
                ),
                "a": Style(
                  color: const Color(0xFF007AFF),
                  textDecoration: TextDecoration.underline,
                ),
                "iframe": Style(
                  display: Display.none,
                ),
              },
            ),
          ],
        );
      } catch (e) {
        print('❌ Error rendering HTML: $e');
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lỗi hiển thị HTML. Hiển thị mô tả thay thế.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDescriptionContent(),
            ],
          ),
        );
      }
    }

    // Fallback to description if no HTML content
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _buildDescriptionContent(),
    );
  }

  Widget _buildDescriptionContent() {
    // Clean description - remove HTML tags if any
    String cleanText = _article.description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    List<String> paragraphs = [];

    if (cleanText.contains('. ')) {
      List<String> sentences = cleanText.split(RegExp(r'\.\s+'));
      String currentParagraph = '';

      for (int i = 0; i < sentences.length; i++) {
        String sentence = sentences[i].trim();
        if (sentence.isEmpty) continue;

        if (i < sentences.length - 1 && !sentence.endsWith('.')) {
          sentence += '.';
        }

        currentParagraph += sentence + ' ';

        if ((i + 1) % 2 == 0 || i == sentences.length - 1) {
          paragraphs.add(currentParagraph.trim());
          currentParagraph = '';
        }
      }
    } else if (cleanText.contains('\n')) {
      paragraphs = cleanText
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    } else {
      const int charsPerParagraph = 300;
      if (cleanText.length > charsPerParagraph) {
        int start = 0;
        while (start < cleanText.length) {
          int end = start + charsPerParagraph;
          if (end >= cleanText.length) {
            paragraphs.add(cleanText.substring(start).trim());
            break;
          }

          int sentenceEnd = cleanText.indexOf('. ', end);
          if (sentenceEnd != -1 && sentenceEnd < end + 100) {
            end = sentenceEnd + 1;
          }

          paragraphs.add(cleanText.substring(start, end).trim());
          start = end;
        }
      } else {
        paragraphs.add(cleanText);
      }
    }

    if (paragraphs.isEmpty && cleanText.isNotEmpty) {
      paragraphs.add(cleanText);
    }

    bool seemsTruncated = cleanText.length > 100 &&
        !cleanText.endsWith('.') &&
        !cleanText.endsWith('!') &&
        !cleanText.endsWith('?');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...paragraphs.map((paragraph) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              paragraph,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.7,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
          );
        }).toList(),

        if (seemsTruncated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Read full article at source...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business_center;
      case 'sports':
        return Icons.sports_soccer;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'science':
        return Icons.science;
      case 'politics':
        return Icons.account_balance;
      default:
        return Icons.article;
    }
  }
}