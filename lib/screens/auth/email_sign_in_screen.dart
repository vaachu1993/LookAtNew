import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../Components/CustomTextField.dart';
import '../../Components/GoogleSignInButton.dart';
import '../../Components/VerifyEmailDialog.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/auth_service.dart';
import '../../services/google_signin_service.dart';

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Xử lý đăng nhập bằng email/password
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(email, password);

      if (!mounted) return;

      // Đăng nhập thành công, chuyển sang HomeScreen (sẽ tự động fetch RSS)
      Navigator.of(context).pushReplacementNamed('/home');

      _showSuccess('Đăng nhập thành công! Xin chào ${response.user.username}');
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');

      // Kiểm tra nếu là lỗi "chưa được xác minh"
      if (errorMessage.contains('chưa được xác minh') ||
          errorMessage.contains('not verified') ||
          errorMessage.contains('kiểm tra email')) {
        _showUnverifiedDialog(email);
      } else {
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Hiển thị dialog khi tài khoản chưa verify
  void _showUnverifiedDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Tài khoản chưa xác nhận',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Tài khoản của bạn chưa được xác nhận. Vui lòng kiểm tra email và nhập mã OTP để xác nhận tài khoản.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToVerifyScreen(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE20035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xác nhận ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Navigate to verify screen
  void _navigateToVerifyScreen(String email) {
    Navigator.of(context).pushNamed(
      '/verify-email',
      arguments: email,
    );
  }

  // Xử lý đăng nhập bằng Google
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 [UI] Starting Google Sign-In...');

      // Lấy Google ID Token
      final String? idToken = await _googleSignInService.getGoogleIdToken();

      if (idToken == null) {
        // User hủy đăng nhập
        print('⚠️ [UI] User cancelled Google Sign-In');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (idToken.isEmpty) {
        throw Exception('Google ID Token rỗng. Vui lòng kiểm tra cấu hình.');
      }

      print('✅ [UI] Got ID Token, calling backend...');

      // Gọi API backend với ID Token
      final response = await _authService.loginWithGoogle(idToken);

      if (!mounted) return;

      print('✅ [UI] Login successful, navigating to HomeScreen...');

      // Đăng nhập thành công, chuyển sang HomeScreen (sẽ tự động fetch RSS)
      Navigator.of(context).pushReplacementNamed('/home');

      _showSuccess('Đăng nhập Google thành công! Xin chào ${response.user.username}');
    } catch (e) {
      print('❌ [UI] Error: $e');
      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Xử lý một số lỗi thường gặp
      if (errorMessage.contains('ID Token')) {
        errorMessage = 'Không thể lấy Google ID Token.\nVui lòng kiểm tra:\n'
            '1. Web Client ID đã cấu hình đúng\n'
            '2. SHA-1 đã thêm vào Firebase\n'
            '3. google-services.json đã cập nhật';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Lỗi'),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
      icon: const Icon(Icons.error),
      primaryColor: Colors.red,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  void _showSuccess(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Thành công'),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle),
      primaryColor: Colors.green,
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

            // Title
            const Text(
              'Chào mừng trở lại',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Chào mừng bạn đến với Look At News',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Email Field
            CustomTextField(
              label: 'Email',
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
            ),

            const SizedBox(height: 20),

            // Password Field
            CustomTextField(
              label: 'Mật khẩu',
              hintText: 'Mật khẩu',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
            ),

            const SizedBox(height: 12),

            // Forget Password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFFE20035),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: height * 0.065,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE20035),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: width * 0.05,
                        height: width * 0.05,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider with "or"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Hoặc',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Google Sign In Button
            GoogleSignInButton(
              onPressed: _isLoading ? () {} : _handleGoogleSignIn,
            ),

            const SizedBox(height: 24),

            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bạn chưa có tài khoản? ',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(
                      color: Color(0xFFE20035),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: _showVerifyEmailDialog,
                child: const Text(
                  'Chưa xác nhận email?',
                  style: TextStyle(
                    color: Color(0xFFE20035),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Show dialog to enter email for verification
  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => VerifyEmailDialog(
        onVerify: (email) {
          Navigator.of(dialogContext).pop();
          Future.delayed(const Duration(milliseconds: 200), () {
            _navigateToVerifyScreen(email);
          });
        },
        onCancel: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}

