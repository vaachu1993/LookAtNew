import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class ArticleContentService {
  /// Fetch and extract article content from URL
  Future<ArticleContentResponse> fetchArticleContent(String url) async {
    try {
      print('🔍 Fetching article from: $url');

      // Validate URL
      if (url.isEmpty || !url.startsWith('http')) {
        print('❌ Invalid URL');
        return ArticleContentResponse(
          isSuccess: false,
          error: 'URL không hợp lệ',
        );
      }

      // Fetch HTML content
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return ArticleContentResponse(
          isSuccess: false,
          error: 'Không thể tải trang (HTTP ${response.statusCode})',
        );
      }

      print('📄 Response body length: ${response.body.length} characters');

      if (response.body.isEmpty) {
        return ArticleContentResponse(
          isSuccess: false,
          error: 'Nội dung trang trống',
        );
      }

      // Parse HTML
      final document = html_parser.parse(response.body);
      print('✅ HTML parsed successfully');

      // Extract article content using common selectors
      String? articleHtml = _extractArticleContent(document, url);

      if (articleHtml == null || articleHtml.isEmpty) {
        print('❌ Could not extract article content');
        return ArticleContentResponse(
          isSuccess: false,
          error: 'Không thể trích xuất nội dung bài báo',
        );
      }

      print('✅ Extracted content length: ${articleHtml.length} characters');

      return ArticleContentResponse(
        isSuccess: true,
        content: articleHtml,
      );
    } on TimeoutException {
      print('⏱️ Timeout fetching article');
      return ArticleContentResponse(
        isSuccess: false,
        error: 'Timeout: Không thể tải được nội dung (quá 15s)',
      );
    } catch (e) {
      print('❌ Error fetching article: $e');
      return ArticleContentResponse(
        isSuccess: false,
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  /// Extract main article content from HTML document
  String? _extractArticleContent(dom.Document document, String url) {
    print('🔎 Extracting content from URL: $url');

    // Add domain-specific selectors
    Map<String, List<String>> domainSelectors = {
      'vnexpress.net': ['.fck_detail', '.sidebar_1', '.Normal'],
      'tuoitre.vn': ['.detail-content', '.content-detail-sapo', '.content'],
      'dantri.com.vn': ['.singular-content', '.detail-content'],
      'thanhnien.vn': ['.detail-content-body', '.content'],
      'vietnamnet.vn': ['.ArticleDetail', '.maincontent'],
      'baomoi.com': ['.article__body', '.content-body'],
    };

    // Try domain-specific selectors first
    for (var entry in domainSelectors.entries) {
      if (url.contains(entry.key)) {
        print('🎯 Found domain match: ${entry.key}');
        for (var selector in entry.value) {
          var element = document.querySelector(selector);
          if (element != null && element.text.trim().length > 100) {
            print('✅ Found content with domain selector: $selector');
            _cleanupElement(element);
            return element.innerHtml;
          }
        }
      }
    }

    // Common article content selectors (ordered by priority)
    final selectors = [
      'article',
      '[role="main"]',
      '.article-content',
      '.post-content',
      '.entry-content',
      '.content-detail',
      '.detail-content',
      '.article-body',
      '.post-body',
      'main article',
      'main .content',
      '#article-content',
      '#post-content',
      '.story-body',
      '.article__body',
      '.post__content',
      '.detail_content',
      '.fck_detail',
    ];

    dom.Element? articleElement;

    // Try each selector
    print('🔍 Trying generic selectors...');
    for (final selector in selectors) {
      articleElement = document.querySelector(selector);
      if (articleElement != null && articleElement.text.trim().length > 100) {
        print('✅ Found content with selector: $selector (${articleElement.text.trim().length} chars)');
        break;
      }
    }

    // If no specific article element found, try to find the largest text block
    if (articleElement == null) {
      print('⚠️ No selector match, trying to find largest text block...');
      articleElement = _findLargestTextBlock(document);
    }

    if (articleElement == null) {
      print('❌ No article element found');
      return null;
    }

      // Clean up the content
      _cleanupElement(articleElement);

      // Get HTML string
      var html = articleElement.innerHtml;

      // Additional sanitization
      html = _sanitizeHtml(html);

      print('✅ Final HTML length: ${html.length} characters');

      // Return HTML string
      return html;
  }

  /// Find the largest text block in the document
  dom.Element? _findLargestTextBlock(dom.Document document) {
    final candidates = document.querySelectorAll('div, section, article');
    print('📊 Found ${candidates.length} candidate elements');

    dom.Element? largest;
    int maxTextLength = 0;

    for (final element in candidates) {
      final textLength = element.text.trim().length;
      if (textLength > maxTextLength && textLength > 500) {
        // Ensure it's not just navigation or ads
        final classNames = element.className.toLowerCase();
        final id = element.id.toLowerCase();

        if (!_isUnwantedElement(classNames, id)) {
          print('📝 Candidate: ${classNames.isEmpty ? id : classNames} - $textLength chars');
          maxTextLength = textLength;
          largest = element;
        }
      }
    }

    if (largest != null) {
      print('✅ Largest text block found: $maxTextLength characters');
    } else {
      print('❌ No suitable text block found');
    }

    return largest;
  }

  /// Check if element is likely navigation, ads, or other unwanted content
  bool _isUnwantedElement(String classNames, String id) {
    final unwantedKeywords = [
      'nav',
      'menu',
      'sidebar',
      'footer',
      'header',
      'ad',
      'advertisement',
      'banner',
      'social',
      'share',
      'comment',
      'related',
      'recommend',
    ];

    for (final keyword in unwantedKeywords) {
      if (classNames.contains(keyword) || id.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Clean up unwanted elements from the article
  void _cleanupElement(dom.Element element) {
    // Remove unwanted tags
    final unwantedTags = [
      'script',
      'style',
      'iframe',
      'noscript',
      'embed',
      'object',
      'video',
      'audio',
      'svg',
      'canvas',
    ];
    for (final tag in unwantedTags) {
      element.querySelectorAll(tag).forEach((e) => e.remove());
    }

    // Remove unwanted elements by class/id
    final unwantedSelectors = [
      '.advertisement',
      '.ad',
      '.ads',
      '.adsbygoogle',
      '.social-share',
      '.share-buttons',
      '.related-articles',
      '.related-posts',
      '.comments',
      '.comment-section',
      '#comments',
      '.sidebar',
      '.navigation',
      '.nav',
      '.menu',
      '.footer',
      '.header',
      '.breadcrumb',
      '.tags',
      '.share',
      '.widget',
      '[class*="banner"]',
      '[id*="banner"]',
      '[class*="popup"]',
      '[id*="popup"]',
    ];

    for (final selector in unwantedSelectors) {
      try {
        element.querySelectorAll(selector).forEach((e) => e.remove());
      } catch (e) {
        // Ignore selector errors
      }
    }

    // Remove empty paragraphs
    element.querySelectorAll('p').forEach((p) {
      if (p.text.trim().isEmpty && p.children.isEmpty) {
        p.remove();
      }
    });

    // Fix images: ensure they have alt text and remove problematic attributes
    final imagesToRemove = <dom.Element>[];
    element.querySelectorAll('img').forEach((img) {
      // Check if image has a valid src
      var src = img.attributes['src'] ?? '';
      var dataSrc = img.attributes['data-src'] ?? '';

      // Try to get valid image URL
      if (src.isEmpty && dataSrc.isNotEmpty) {
        src = dataSrc;
        img.attributes['src'] = src;
      }

      // Remove image if no valid src or invalid URL
      if (src.isEmpty ||
          src.startsWith('data:image/gif;base64') || // tracking pixels
          src.contains('1x1') || // 1x1 tracking images
          src.endsWith('.gif') && src.length < 50) { // small gifs
        imagesToRemove.add(img);
        return;
      }

      // Remove width/height attributes to allow responsive sizing
      img.attributes.remove('width');
      img.attributes.remove('height');

      // Ensure alt attribute exists
      if (!img.attributes.containsKey('alt')) {
        img.attributes['alt'] = '';
      }

      // Remove data-src
      img.attributes.remove('data-src');

      // Remove srcset if exists (can cause issues)
      img.attributes.remove('srcset');
      img.attributes.remove('sizes');

      // Remove loading attribute
      img.attributes.remove('loading');

      // Remove inline styles
      img.attributes.remove('style');
    });

    // Remove invalid images
    for (var img in imagesToRemove) {
      img.remove();
    }

    // Remove figure elements that don't contain any images
    element.querySelectorAll('figure').forEach((figure) {
      final hasImage = figure.querySelectorAll('img').isNotEmpty;
      if (!hasImage) {
        figure.remove();
      }
    });

    // Remove standalone figcaptions (those not inside figure)
    element.querySelectorAll('figcaption').forEach((figcaption) {
      // Check if parent is not a figure
      if (figcaption.parent?.localName != 'figure') {
        figcaption.remove();
      }
    });

    // Remove nested divs that are empty or only contain whitespace
    element.querySelectorAll('div').forEach((div) {
      if (div.text.trim().isEmpty && div.children.isEmpty) {
        div.remove();
      }
    });

    // Simplify tables (they can cause layout issues)
    element.querySelectorAll('table').forEach((table) {
      // Remove inline styles that might conflict
      table.attributes.remove('style');
      table.attributes.remove('width');
      table.attributes.remove('height');

      // Remove cellspacing, cellpadding
      table.attributes.remove('cellspacing');
      table.attributes.remove('cellpadding');
      table.attributes.remove('border');
    });

    // Remove all inline styles that might cause issues
    element.querySelectorAll('[style]').forEach((el) {
      final style = el.attributes['style'] ?? '';

      // Keep only safe styles
      if (!style.contains('position') && !style.contains('float')) {
        // Keep the style
      } else {
        el.attributes.remove('style');
      }
    });
  }

  /// Sanitize HTML string to remove problematic patterns
  String _sanitizeHtml(String html) {
    // Remove comments
    html = html.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    // Remove inline event handlers
    html = html.replaceAll(RegExp(r'on\w+="[^"]*"', caseSensitive: false), '');
    html = html.replaceAll(RegExp(r"on\w+='[^']*'", caseSensitive: false), '');

    // Remove dangerous attributes
    html = html.replaceAll(RegExp(r'\sdata-[\w-]+="[^"]*"'), '');

    // Limit excessive whitespace
    html = html.replaceAll(RegExp(r'\s+'), ' ');
    html = html.replaceAll(RegExp(r'>\s+<'), '><');

    return html.trim();
  }
}

class ArticleContentResponse {
  final bool isSuccess;
  final String? content;
  final String? error;

  ArticleContentResponse({
    required this.isSuccess,
    this.content,
    this.error,
  });
}
