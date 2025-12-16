import 'dart:async';
import 'package:app_links/app_links.dart';

/// Service để xử lý Deep Links (email verification, password reset, etc.)
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Callback khi nhận deep link
  Function(Uri)? onLink;

  /// Initialize deep link listener
  Future<void> init() async {
    // Handle initial deep link (when app is opened from link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('🔗 [DeepLink] Initial link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('❌ [DeepLink] Failed to get initial link: $e');
    }

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('🔗 [DeepLink] Received link: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ [DeepLink] Error: $err');
      },
    );
  }

  /// Process deep link
  void _handleDeepLink(Uri uri) {
    if (onLink != null) {
      onLink!(uri);
    }
  }

  /// Dispose
  void dispose() {
    _linkSubscription?.cancel();
  }

  /// Parse verification token from URI
  /// Supports:
  /// - lookat://verify?token=xxx
  /// - https://yourdomain.com/verify?token=xxx
  static String? parseVerificationToken(Uri uri) {
    if (uri.scheme == 'lookat' && uri.host == 'verify') {
      return uri.queryParameters['token'];
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.contains('verify')) {
      return uri.queryParameters['token'];
    }

    return null;
  }

  /// Parse password reset token from URI
  static String? parsePasswordResetToken(Uri uri) {
    if (uri.scheme == 'lookat' && uri.host == 'reset-password') {
      return uri.queryParameters['token'];
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.path.contains('reset-password')) {
      return uri.queryParameters['token'];
    }

    return null;
  }
}

