import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ Thư viện (Gallery) hoặc Máy ảnh (Camera)
  /// Trả về chuỗi Data URL Base64 để lưu thẳng vào trường 'image'
  /// Hoạt động mượt mà trên cả Web và Di động (Android/iOS)
  static Future<String?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (file == null) return null;
      final Uint8List bytes = await file.readAsBytes();
      final String base64String = base64Encode(bytes);
      // Trả về dạng Data URL Base64
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Lỗi khi chọn ảnh: $e');
      return null;
    }
  }

  /// Widget hiển thị hình ảnh sản phẩm hỗ trợ cả Base64, URL Web và Icon mặc định
  static Widget buildProductImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // 1. Kiểm tra nếu là Base64 Data URI
      if (imageUrl.startsWith('data:image')) {
        try {
          final parts = imageUrl.split(',');
          if (parts.length > 1) {
            final Uint8List bytes = base64Decode(parts[1]);
            return ClipRRect(
              borderRadius: radius,
              child: Image.memory(
                bytes,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallback(width, height, radius),
              ),
            );
          }
        } catch (e) {
          debugPrint('Lỗi giải mã base64 ảnh sản phẩm: $e');
        }
      }

      // 2. Kiểm tra nếu là đường dẫn HTTP/HTTPS URL thông thường
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallback(width, height, radius),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    return _buildFallback(width, height, radius);
  }

  static Widget _buildFallback(double? width, double? height, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: radius,
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade500,
        size: (width != null && height != null) ? (width < height ? width * 0.5 : height * 0.5) : 32,
      ),
    );
  }
}
