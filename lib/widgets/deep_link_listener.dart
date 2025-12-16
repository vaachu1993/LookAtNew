import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../screens/auth/reset_password_screen.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;

  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    // Khi app đã mở và nhận link
    _appLinks.uriLinkStream.listen(_handleLink);

    // Khi mở app từ deep link lần đầu
    _initInitialLink();
  }

  Future<void> _initInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleLink(uri);
    }
  }

  void _handleLink(Uri uri) {
    debugPrint("🔗 Deep Link nhận được: $uri");

    if (uri.scheme == "lookat" && uri.host == "reset-password") {
      final token = uri.queryParameters["token"];
      if (token != null && token.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(token: token),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
