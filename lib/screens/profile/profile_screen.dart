import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../../core/api_client.dart';
import '../../core/image_picker_helper.dart';
import '../../models/user.dart';
import '../../widgets/common_bottom_nav_bar.dart';
import '../../Utils/Utils.dart';
import 'edit_name_dialog.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient();

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Utils.selectIndex = 4;
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if user has valid token before loading data
    final token = await _apiClient.authStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      //Không có token thì không thể load dữ liệu
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng đăng nhập để xem thông tin tài khoản'),
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      });
      return;
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiClient.getCurrentUser();
      if (!mounted) return;

      if (result.success && result.data != null) {
        setState(() {
          _user = result.data!;
        });
      } else {
        if (result.statusCode == 401) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
                backgroundColor: Colors.orange.shade900,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
          return;
        }

        _showError(result.message ?? 'Không thể lấy thông tin user');
      }
    } catch (e) {
      if (mounted) {
        _showError('Có lỗi xảy ra: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      final result = await _apiClient.updateUser(username: newUsername);
      if (!mounted) return;
      if (result.success && result.data != null) {
        await _loadUserData();
        _showSuccess('Cập nhật tên thành công');
      } else {
        _showError(result.message ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      if (mounted) {
        _showError('Có lỗi xảy ra: ${e.toString()}');
      }
    }
  }

  Future<void> _updateAvatar() async {
    try {
      debugPrint('🔄 Starting avatar update process...');

      final imageFile = await ImagePickerHelper.pickAndCropImage(context);
      debugPrint('📸 Image picker result: ${imageFile?.path}');

      if (imageFile == null) {
        debugPrint('❌ User cancelled image selection');
        return;
      }

      if (!mounted) return;

      ImagePickerHelper.showLoadingDialog(context, message: 'Đang xử lý ảnh...');
      debugPrint('Hiển thị dialog loading...');

      // Convert cropped image to base64 data URL
      debugPrint('Chuyển ảnh đã cắt thành base64...');
      final avatarUrl = await _convertImageToBase64(imageFile.path);

      if (!mounted) return;
      Navigator.of(context).pop();

      debugPrint('Cập nhật avt mới');
      final updateResult = await _apiClient.updateUser(avatarUrl: avatarUrl);
      debugPrint('🔄 Update result: success=${updateResult.success}, message=${updateResult.message}');

      if (!mounted) return;

      if (updateResult.success) {
        await _loadUserData();
        _showSuccess('Cập nhật ảnh đại diện thành công');
        debugPrint('Avatar update completed successfully');
      } else {
        debugPrint('Update failed: ${updateResult.message}');
        _showError(updateResult.message ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        _showError('Có lỗi xảy ra: ${e.toString()}');
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE20035).withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFFE20035),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiClient.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade900,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade900,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _showFeatureInDevelopment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Tính năng đang phát triển',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE20035),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    // Check if user is Google account
    if (_user?.isGoogleAccount == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Không thể đổi mật khẩu',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Tài khoản Google không thể đổi mật khẩu tại đây. Vui lòng quản lý mật khẩu qua tài khoản Google của bạn.',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE20035),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to change password screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _showEditNameDialog() {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (context) => EditNameDialog(
        currentName: _user!.username,
        onSave: _updateUsername,
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE20035), width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE20035).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: _user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
            ? _buildAvatarImage(_user!.avatarUrl!)
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildAvatarImage(String avatarUrl) {
    // Check if it's a data URL (base64)
    if (avatarUrl.startsWith('data:image/')) {
      try {
        // Extract base64 data from data URL
        final base64Data = avatarUrl.split(',')[1];
        final bytes = base64Decode(base64Data);

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      } catch (e) {
        debugPrint('Error decoding base64 avatar: $e');
        return _buildDefaultAvatar();
      }
    } else {
      // Regular HTTP URL
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
  }

  Widget _buildDefaultAvatar() {
    final username = _user?.username ?? "";
    final initial = username.trim().isEmpty ? "?" : username.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFFF5F5F7),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE20035),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showChevron = true,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDanger ? const Color(0xFFE20035).withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDanger ? const Color(0xFFE20035) : const Color(0xFF1C1C1E),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? const Color(0xFFE20035) : const Color(0xFF1C1C1E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                ),
              )
            : null,
        trailing: showChevron
            ? Icon(
                Icons.chevron_right,
                color: const Color(0xFF8E8E93),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE20035),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'Tài khoản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Quản lý thông tin cá nhân',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and name section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      _buildAvatar(),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _updateAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE20035),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.username,
                    style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.email,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Settings section
            _buildSectionHeader('Cài đặt tài khoản'),
            _buildProfileItem(
              icon: Icons.edit_outlined,
              title: 'Sửa tên hiển thị',
              subtitle: _user!.username,
              onTap: _showEditNameDialog,
            ),
            _buildProfileItem(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: _user!.email,
              showChevron: false,
            ),
            _buildProfileItem(
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              onTap: _handleChangePassword,
            ),

            // Preferences section
            _buildSectionHeader('Tùy chọn'),
            _buildProfileItem(
              icon: Icons.notifications_outlined,
              title: 'Thông báo',
              onTap: _showFeatureInDevelopment,
            ),
            _buildProfileItem(
              icon: Icons.language_outlined,
              title: 'Ngôn ngữ',
              subtitle: 'Tiếng Việt',
              onTap: _showFeatureInDevelopment,
            ),
            _buildProfileItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Quyền riêng tư',
              onTap: _showFeatureInDevelopment,
            ),

            // Danger zone
            _buildSectionHeader('Tài khoản'),
            _buildProfileItem(
              icon: Icons.logout,
              title: 'Đăng xuất',
              onTap: _handleLogout,
              showChevron: false,
              isDanger: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return const CommonBottomNavBar();
  }

  Future<String> _convertImageToBase64(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File không tồn tại');
    }

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Không thể decode ảnh');
    }

    final resizedImage = img.copyResize(image, width: 200, height: 200);
    final jpegBytes = img.encodeJpg(resizedImage, quality: 80);
    final base64Image = base64Encode(jpegBytes);
    final mimeType = 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,$base64Image';

    return dataUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE20035)),
                ),
              )
            : _user == null
                ? _buildErrorState()
                : RefreshIndicator(
                    color: const Color(0xFFE20035),
                    backgroundColor: const Color(0xFF151515),
                    onRefresh: _loadUserData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          _buildProfileHeader(),
                          const SizedBox(height: 24),

                          // Profile content (white background)
                          _buildProfileContent(),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE20035),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải thông tin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng thử lại',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE20035),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Thử lại',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
