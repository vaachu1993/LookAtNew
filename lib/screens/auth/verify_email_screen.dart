import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();

  // Controllers cho 6 ô nhập OTP
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 56;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }


  /// Get OTP code from controllers
  String _getOTPCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  /// Verify OTP
  Future<void> _verifyOTP() async {
    final otpCode = _getOTPCode();

    if (otpCode.length != 6) {
      _showError('Vui lòng nhập đầy đủ 6 chữ số');
      return;
    }

    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      print('🔵 [VerifyEmail] Verifying OTP: $otpCode');
      final message = await _authService.verifyOTP(
        email: widget.email,
        otpCode: otpCode,
      );

      if (!mounted) return;

      print('✅ [VerifyEmail] Success: $message');

      _showSuccess(message);

      // Navigate to login after 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('❌ [VerifyEmail] Error: $e');

      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Resend OTP
  Future<void> _resendOTP() async {
    if (_isResending || _resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      print('🔵 [VerifyEmail] Resending OTP to ${widget.email}');
      final message = await _authService.resendOTP(widget.email);

      if (!mounted) return;

      print('✅ [VerifyEmail] Resend success: $message');
      _showSuccess(message);

      // Start countdown (60 seconds)
      setState(() => _resendCountdown = 60);
      _startCountdown();
    } catch (e) {
      print('❌ [VerifyEmail] Resend error: $e');

      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Start countdown timer
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startCountdown();
      }
    });
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

  Widget _buildOTPBox(int index) {

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final hasFocus = _focusNodes[index].hasFocus;
    final boxWidth = width * 0.12;
    final boxHeight = height * 0.07;

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus
              ? const Color(0xFFE91E63) // Pink border when focused
              : const Color(0xFFE0E0E0), // Light gray border
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last field, unfocus and auto-verify
              _focusNodes[index].unfocus();
              _verifyOTP();
            }
          } else {
            // Move to previous field when deleting
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {}); // Rebuild to update border color
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery
        .of(context)
        .size
        .width;
    double height = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Vui lòng không tiết lộ mã OTP ra bên ngoài để đảm bảo an toàn.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                      (index) => _buildOTPBox(index),
                ),
              ),

              const SizedBox(height: 32),

              // Countdown text
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                    children: [
                      const TextSpan(text: 'Bạn có thể yêu cầu gửi lại mã trong '),
                      TextSpan(
                        text: '$_resendCountdown giây',
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend Code Button
              Center(
                child: TextButton(
                  onPressed: (_isResending || _resendCountdown > 0)
                      ? null
                      : _resendOTP,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Gửi lại mã.',
                    style: TextStyle(
                      fontSize: 16,
                      color: (_isResending || _resendCountdown > 0)
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFFE91E63),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
