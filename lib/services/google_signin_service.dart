import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  // Singleton pattern
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  // Web Client ID từ Google Cloud Console
  // ⚠️ QUAN TRỌNG: Đây phải là Web Client ID, không phải Android Client ID
  static const String serverClientId =
      '706618149089-4tnjpt3kgdoetkrf80m89kijq8cn67le.apps.googleusercontent.com';

  // Google Sign-In instance với cấu hình đầy đủ
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid', // Quan trọng để lấy ID Token
    ],
    serverClientId: serverClientId, // Web Client ID
  );

  /// Lấy Google ID Token
  /// Returns: idToken (String) hoặc null nếu thất bại
  Future<String?> getGoogleIdToken() async {
    try {
      print('🔵 [GoogleSignIn] Starting sign in process...');

      // Sign out trước để đảm bảo hiển thị account picker
      await _googleSignIn.signOut();

      // Bắt đầu flow đăng nhập Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        print('⚠️ [GoogleSignIn] User cancelled sign in');
        return null;
      }

      print('✅ [GoogleSignIn] User selected: ${account.email}');

      // Lấy authentication data
      final GoogleSignInAuthentication auth = await account.authentication;

      // Kiểm tra idToken
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        print('❌ [GoogleSignIn] ID Token is null or empty!');
        print('❌ [GoogleSignIn] Access Token: ${auth.accessToken?.substring(0, 20)}...');
        throw Exception('Không thể lấy Google ID Token. Vui lòng kiểm tra cấu hình.');
      }

      print('✅ [GoogleSignIn] ID Token obtained successfully');
      print('✅ [GoogleSignIn] Token length: ${idToken.length}');
      print('✅ [GoogleSignIn] Token preview: ${idToken.substring(0, 30)}...');

      return idToken;
    } catch (e) {
      print('❌ [GoogleSignIn] Error: $e');
      rethrow;
    }
  }

  /// Sign out khỏi Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ [GoogleSignIn] Signed out successfully');
    } catch (e) {
      print('❌ [GoogleSignIn] Sign out error: $e');
    }
  }

  /// Kiểm tra trạng thái đăng nhập hiện tại
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('❌ [GoogleSignIn] Silent sign in error: $e');
      return null;
    }
  }

  /// Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      print('✅ [GoogleSignIn] Disconnected successfully');
    } catch (e) {
      print('❌ [GoogleSignIn] Disconnect error: $e');
    }
  }
}

