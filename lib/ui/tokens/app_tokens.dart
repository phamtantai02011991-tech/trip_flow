import 'package:flutter/material.dart';

/// Token thiết kế duy nhất của TripFlow — nguồn màu/chữ/bo góc cho toàn app.
///
/// Quy ước: **không** dùng `Color(0x...)` trực tiếp trong `features/`; chỉ dùng
/// các hằng số ở đây. Bảng token lấy từ 8 ảnh tham chiếu người dùng cung cấp
/// (xem `docs/02-DESIGN-SYSTEM.md`).
abstract final class AppColors {
  // Thương hiệu
  static const coral = Color(0xFFFF4B55);
  static const coralDark = Color(0xFFE03A44);
  static const coralSoft = Color(0xFFFFEDEE);
  static const terracotta = Color(0xFFC2703F);
  static const cream = Color(0xFFFAF7F2);
  static const ink = Color(0xFF14161A);

  // Bề mặt
  static const bg = cream;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF3EFE8);
  static const line = Color(0xFFE8E2D9);

  // Chữ
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF6B7078);
  static const textTertiary = Color(0xFF9AA0A6);
  static const textOnDark = Color(0xFFF5F5F7);

  // Bản đồ tối
  static const mapDarkBg = Color(0xFF1C1C1E);
  static const mapDarkCard = Color(0xFF262628);
  static const mapDarkLine = Color(0xFF3A3A3C);

  // Ngữ nghĩa
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF2E6BFF);

  // Phân loại điểm dừng
  static const kindFood = Color(0xFFF97316);
  static const kindCafe = Color(0xFF8B5E34);
  static const kindHotel = Color(0xFF7C3AED);
  static const kindGas = Color(0xFF2563EB);
  static const kindEv = Color(0xFF12B76A);
  static const kindRest = Color(0xFF0EA5E9);
  static const kindSight = Color(0xFFE11D48);

  /// Gradient phủ đáy ảnh để chữ trắng đọc được (ảnh 1, 3).
  static const photoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x14000000), Color(0xCC000000)],
    stops: [0.35, 0.6, 1.0],
  );
}

abstract final class AppSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
}

abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
  static const sheet = 32.0;
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppShadow {
  static const card = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 32, offset: Offset(0, 14)),
  ];
  static const marker = [
    BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

abstract final class AppText {
  static const display = TextStyle(
    fontSize: 30,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontSize: 24,
    height: 1.18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontSize: 17,
    height: 1.28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const bodySm = TextStyle(
    fontSize: 13.5,
    height: 1.42,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const label = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
}
