import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose between camera and gallery
  static Future<File?> pickAndCropImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFF9D47C)),
                title: const Text(
                  'Chụp ảnh',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFF9D47C)),
                title: const Text(
                  'Chọn từ thư viện',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFFAAAAAA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    try {
      // Request permissions based on source
      bool permissionGranted = false;

      if (source == ImageSource.camera) {
        // Request camera permission
        final status = await Permission.camera.request();
        permissionGranted = status.isGranted;

        if (status.isDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(
              context,
              'Camera',
              'Ứng dụng cần quyền truy cập camera để chụp ảnh',
            );
          }
          return null;
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showOpenSettingsDialog(context, 'camera');
          }
          return null;
        }
      } else {
        // Request storage/photos permission for gallery
        PermissionStatus status;

        // Android 13+ uses photos permission, older versions use storage
        if (Platform.isAndroid) {
          final androidInfo = await _getAndroidVersion();
          if (androidInfo >= 33) {
            status = await Permission.photos.request();
          } else {
            status = await Permission.storage.request();
          }
        } else {
          status = await Permission.photos.request();
        }

        permissionGranted = status.isGranted;

        if (status.isDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(
              context,
              'Thư viện',
              'Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh',
            );
          }
          return null;
        }

        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showOpenSettingsDialog(context, 'thư viện ảnh');
          }
          return null;
        }
      }

      if (!permissionGranted) {
        debugPrint('Permission not granted');
        return null;
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Crop image to 1:1 aspect ratio
      final croppedFile = await _cropImage(pickedFile.path);

      return croppedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Crop image to 1:1 aspect ratio
  static Future<File?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,

        // 🔥 Bản mới = tự set ratio, không còn preset
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Chỉnh sửa ảnh',
            toolbarColor: const Color(0xFF151515),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFF9D47C),

            // ❌ KHÔNG còn initAspectRatio
            // ❌ KHÔNG còn CropAspectRatioPreset
            lockAspectRatio: true,

            hideBottomControls: false,
            showCropGrid: true,
            cropFrameColor: const Color(0xFFF9D47C),
            cropGridColor: const Color(0xFF555555),
            statusBarColor: const Color(0xFF151515),
            backgroundColor: Colors.black,
            dimmedLayerColor: Colors.black54,
          ),

          IOSUiSettings(
            title: 'Chỉnh sửa ảnh',

            // 🔥 Khóa đúng tỷ lệ 1:1
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            aspectRatioLockDimensionSwapEnabled: false,
            cancelButtonTitle: 'Hủy',
            doneButtonTitle: 'Xong',
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;

    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }


  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF9D47C)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message ?? 'Đang xử lý...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show permission denied dialog
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Cần quyền $permissionName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFFF9D47C)),
            ),
          ),
        ],
      ),
    );
  }

  /// Show open settings dialog
  static void _showOpenSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Quyền bị từ chối',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn đã từ chối quyền truy cập $permissionName. Vui lòng mở Cài đặt và cấp quyền để sử dụng tính năng này.',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text(
              'Mở Cài đặt',
              style: TextStyle(color: Color(0xFFF9D47C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Get Android SDK version
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // This is a simple check, you might need to use a plugin for exact version
      // For now, we'll assume modern Android
      return 33; // Android 13+
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return 30; // Fallback to Android 11
    }
  }
}

