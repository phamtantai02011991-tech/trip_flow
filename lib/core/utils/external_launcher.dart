import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper tiện ích khởi chạy ứng dụng ngoài: Cuộc gọi, Bản đồ dẫn đường, URL Đối tác OTA, SMS Cứu hộ
class ExternalLauncher {
  ExternalLauncher._();

  /// Thực hiện cuộc gọi khẩn cấp hoặc liên hệ hotline 1 chạm
  static Future<bool> makePhoneCall(BuildContext context, String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      _showToast(context, 'Số điện thoại không hợp lệ: $rawPhone', isError: true);
      return false;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        // Fallback: Copy vào clipboard
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (context.mounted) {
          _showToast(context, 'Đã sao chép số điện thoại: $cleanPhone');
        }
        return true;
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (context.mounted) {
        _showToast(context, 'Đã sao chép số hotline: $cleanPhone');
      }
      return false;
    }
  }

  /// Mở Google Maps điều hướng trực tiếp đến tọa độ
  static Future<bool> openMapNavigation({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String destinationName,
  }) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showToast(context, 'Không thể mở ứng dụng bản đồ', isError: true);
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        _showToast(context, 'Lỗi mở bản đồ: $e', isError: true);
      }
      return false;
    }
  }

  /// Mở liên kết Đối tác OTA (Agoda, Booking, Vexere, Traveloka, Klook)
  static Future<bool> openOtaPartner({
    required BuildContext context,
    required String partnerName,
    required String affiliateUrl,
    String? promoCode,
  }) async {
    if (promoCode != null && promoCode.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: promoCode));
      if (context.mounted) {
        _showToast(
          context,
          'Đã sao chép mã ưu đãi [$promoCode]! Đang mở $partnerName...',
          isError: false,
        );
      }
    }

    final uri = Uri.parse(affiliateUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showToast(context, 'Không thể mở liên kết đối tác $partnerName', isError: true);
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        _showToast(context, 'Lỗi kết nối $partnerName: $e', isError: true);
      }
      return false;
    }
  }

  /// Gửi tin nhắn SMS khẩn cấp Biker SOS kèm tọa độ GPS
  static Future<bool> sendEmergencySms({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': message},
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        if (context.mounted) {
          _showToast(context, 'Đã copy tin nhắn SOS và tọa độ GPS vào bộ nhớ tạm!');
        }
        return true;
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        _showToast(context, 'Đã copy tọa độ SOS vào bộ nhớ tạm');
      }
      return false;
    }
  }

  static void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

