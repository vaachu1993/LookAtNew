import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import '../../models/article_model.dart';
import '../../models/favorite_model.dart';
import '../../services/favorite_service.dart';

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
  late ArticleModel _article;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in browser'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open in browser
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Copy link'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Copy to clipboard
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Report article
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            _buildHeroImage(),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildTitle(),
                  const SizedBox(height: 20),

                  // Source Section
                  _buildSourceSection(),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                  const SizedBox(height: 24),

                  // Body Content
                  _buildBodyContent(),
                  const SizedBox(height: 40),
                ],
              ),
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
    // Clean description - remove HTML tags if any
    String cleanText = _article.description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // If description is too short, expand it with better formatting
    List<String> paragraphs = [];

    // Try to split by common delimiters
    if (cleanText.contains('. ')) {
      // Split by sentences and group into paragraphs
      List<String> sentences = cleanText.split(RegExp(r'\.\s+'));
      String currentParagraph = '';

      for (int i = 0; i < sentences.length; i++) {
        String sentence = sentences[i].trim();
        if (sentence.isEmpty) continue;

        // Add period back if not last sentence
        if (i < sentences.length - 1 && !sentence.endsWith('.')) {
          sentence += '.';
        }

        currentParagraph += sentence + ' ';

        // Create new paragraph every 2-3 sentences
        if ((i + 1) % 2 == 0 || i == sentences.length - 1) {
          paragraphs.add(currentParagraph.trim());
          currentParagraph = '';
        }
      }
    } else if (cleanText.contains('\n')) {
      // Split by line breaks
      paragraphs = cleanText
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    } else {
      // If no natural breaks, split by character count
      const int charsPerParagraph = 300;
      if (cleanText.length > charsPerParagraph) {
        int start = 0;
        while (start < cleanText.length) {
          int end = start + charsPerParagraph;
          if (end >= cleanText.length) {
            paragraphs.add(cleanText.substring(start).trim());
            break;
          }

          // Find nearest sentence end
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

    // Ensure we have at least some content
    if (paragraphs.isEmpty && cleanText.isNotEmpty) {
      paragraphs.add(cleanText);
    }

    // Add a continuation hint if content seems truncated
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

        // Add "Read more" hint if content seems truncated
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

