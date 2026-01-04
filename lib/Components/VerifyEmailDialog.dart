import 'package:flutter/material.dart';

class VerifyEmailDialog extends StatefulWidget {
  final Function(String) onVerify;
  final VoidCallback onCancel;

  const VerifyEmailDialog({
    super.key,
    required this.onVerify,
    required this.onCancel,
  });

  @override
  State<VerifyEmailDialog> createState() => _VerifyEmailDialogState();
}

class _VerifyEmailDialogState extends State<VerifyEmailDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập email';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorText = 'Email không hợp lệ';
      });
      return;
    }

    widget.onVerify(email);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xác nhận tài khoản',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhập email của tài khoản chưa được xác nhận:',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: false,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
                onSubmitted: (_) => _handleContinue(),
                decoration: InputDecoration(
                  hintText: 'Email',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE20035),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tiếp tục', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

