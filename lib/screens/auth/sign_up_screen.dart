import 'package:flutter/material.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/google_sign_in_button.dart';
import '../../services/auth_service.dart';
import '../../services/google_signin_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Xử lý đăng ký
  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (password.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo avatar mặc định từ tên người dùng
      final defaultAvatar = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&size=200&background=random';

      final message = await _authService.registerUser(
        username: name,
        email: email,
        password: password,
        avatarUrl: defaultAvatar, // Dùng avatar mặc định từ UI Avatars
      );

      if (!mounted) return;

      // Hiển thị thông báo thành công
      _showSuccess(message);

      // Chờ 1 giây rồi chuyển sang màn hình verify email
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Navigate to verify email screen
      Navigator.of(context).pushReplacementNamed(
        '/verify-email',
        arguments: email, // Pass email to verify screen
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Xử lý đăng ký bằng Google
  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 [SignUp] Starting Google Sign-Up...');

      // Lấy Google ID Token
      final String? idToken = await _googleSignInService.getGoogleIdToken();

      if (idToken == null) {
        // User hủy đăng nhập
        print('⚠️ [SignUp] User cancelled Google Sign-Up');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (idToken.isEmpty) {
        throw Exception('Google ID Token rỗng. Vui lòng kiểm tra cấu hình.');
      }

      print('✅ [SignUp] Got ID Token, calling backend...');

      // Gọi API backend (Google Sign-Up cũng dùng endpoint /google)
      final response = await _authService.loginWithGoogle(idToken);

      if (!mounted) return;

      print('✅ [SignUp] Sign-up successful, navigating to HomeScreen...');

      // Đăng ký thành công, chuyển sang HomeScreen
      Navigator.of(context).pushReplacementNamed('/home');

      _showSuccess('Đăng ký Google thành công! Xin chào ${response.user.username}');
    } catch (e) {
      print('❌ [SignUp] Error: $e');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Create Account',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Join FastNews today',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Name Field
              CustomTextField(
                label: 'Full Name',
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
              ),

              const SizedBox(height: 20),

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
                label: 'Password',
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),

              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
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
                      'or',
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

              // Google Sign Up Button
              GoogleSignInButton(
                onPressed: _isLoading ? () {} : _handleGoogleSignUp,
              ),

              const SizedBox(height: 24),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFFE20035),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

